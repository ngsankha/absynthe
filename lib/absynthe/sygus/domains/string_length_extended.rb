require 'lazyz3'
Integer.prepend LazyZ3::Int
TrueClass.prepend LazyZ3::Bool
FalseClass.prepend LazyZ3::Bool

# class Interval
#   attr_accessor :l, :u

#   def initialize(l, u)
#     raise AbsyntheError, "#{l} should be less than or equal to #{u}" unless l <= u
#     @l = l
#     @u = u
#   end

#   def ==(rhs)
#     @l == rhs.l && @u == rhs.u
#   end

#   def <=(rhs)
#     rhs.l <= @l && @u <= rhs.u
#   end

#   def +(rhs)
#     Interval.new(@l + rhs.l, @u + rhs.u)
#   end

#   def -(rhs)
#     Interval.new(@l - rhs.l, @u - rhs.u)
#   end

#   def to_s
#     "[#{@l}, #{@u}]"
#   end
# end

# String length domain backed by Z3

# TODO: there is no way to distinguish strings and integers when lifted to
# this domain. Is that fine?
class StringLenExt < AbstractDomain
  attr_reader :attrs, :variant, :asserts

  private_class_method :new

  def initialize(variant, **attrs)
    @variant = variant
    @attrs = attrs
    @asserts = []
  end

  @@top = new(:top)
  @@bot = new(:bot)

  def self.top
    @@top
  end

  def self.bot
    @@bot
  end

  def self.var(name)
    var_val_impl(name)
  end

  def self.val(v)
    var_val_impl(v)
  end

  def top?
    @variant == :top
  end

  def bot?
    @variant == :bot
  end

  def var?
    false
  end

  def val?
    true
  end

  def val_leq(lhs, rhs)
    concrete_leq(lhs, rhs)
  end

  def var_leq(lhs, rhs)
    concrete_leq(lhs, rhs)
  end

  def ==(rhs)
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
    @variant == rhs.variant && @attrs == rhs.attrs
  end

  def self.from(val)
    case val
    when String
      StringLenExt.val(val.length)
    when Integer, true, false
      StringLenExt.val(val)
    else
      raise AbsyntheError, "unexpected type"
    end
  end

  def to_s
    if top?
      "⊤"
    elsif bot?
      "⊥"
    elsif var?
      "?#{@attrs[:name]}"
    else
      "#{@attrs[:val]}"
    end
  end

  def solve
    raise AbsyntheError, "unimplemented!"
  end

  # returns a fresh dependent hole when possible
  def self.replace_dep_hole!(name, args)
    case name
    when :"str.++"
      args[1] = s(:dephole, :ntString, self.fresh_var)
    when :"str.replace"
      return
    when :"str.at"
      return
    when :"int.to.str"
      return
    when :"str.substr"
      args[2] = s(:dephole, :ntInt, self.fresh_var)
    when :+
      args[1] = s(:dephole, :ntInt, self.fresh_var)
    when :-
      args[1] = s(:dephole, :ntInt, self.fresh_var)
    when :"str.len"
      args[0] = s(:dephole, :ntString, self.fresh_var)
    when :"str.to.int"
      return
    when :"str.indexof"
      return
    when :"str.prefixof"
      return
    when :"str.suffixof"
      return
    when :"str.contains"
      return
    else
    end
  end

  private
  def self.var_val_impl(v)
    case v
    when String
      z3val = LazyZ3::var_int(v)
      res = new(:val, val: z3val)
      res.asserts << (z3val >= 0)
      res
    when LazyZ3::Z3Node, Integer, true, false
      new(:val, val: v)
    else
      raise AbsyntheError, "unexpected type #{v.class}"
    end
  end

  def val_z3?
    @attrs[:val].is_a?(LazyZ3::Z3Node)
  end

  # combines all assertions collected till now with a conjunction
  def combine_asserts(lhs, rhs)
    all_asserts = lhs.asserts + rhs.asserts
    all_asserts.reject! { |a| a.is_a?(TrueClass) }
    return false if all_asserts.any? { |a| a.is_a?(FalseClass) }

    base = (lhs.attrs[:val] == rhs.attrs[:val])
    if all_asserts.empty?
      puts "WARNING: No assumptions, is this correct?"
      base
    else
      all_asserts.reduce(:&) & base
    end
  end

  # evaluates using Z3 to check the <= relation
  def concrete_leq(lhs, rhs)
    if lhs.attrs[:val].is_a?(LazyZ3::Z3Node) ||
       rhs.attrs[:val].is_a?(LazyZ3::Z3Node)
      expr = combine_asserts(lhs, rhs)
      return false if (expr.is_a? FalseClass)

      e = LazyZ3::Evaluator.new
      result = e.solve(expr)
      if result
        Globals.prev_model = e.model
      end
      result
    else
      lhs.attrs[:val] == rhs.attrs[:val]
    end
  end
end
