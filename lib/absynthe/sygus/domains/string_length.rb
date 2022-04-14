class StringLength < AbstractDomain
  include VarName
  attr_reader :attrs, :variant

  private_class_method :new

  def initialize(variant, **attrs)
    @variant = variant
    @attrs = attrs
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
    result = new(:var, name: name)
    result.glb = @@bot
    result.lub = @@top
    result
  end

  def self.val(l, u)
    new(:val, l: l, u: u)
  end

  def top?
    @variant == :top
  end

  def bot?
    @variant == :bot
  end

  def var?
    @variant == :var
  end

  def val?
    @variant == :val
  end

  def val_leq(lhs, rhs)
    rhs.attrs[:l] <= lhs.attrs[:l] && lhs.attrs[:u] <= rhs.attrs[:u]
  end

  def var_leq(lhs, rhs)
    # NOTE: This assumes all ground variables are distinct
    false
  end

  def ==(rhs)
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
    @variant == rhs.variant && @attrs == rhs.attrs
  end

  def self.from(val)
    case val
    when String
      StringLength.val(val.length, val.length)
    when Integer, true, false
      StringLength.bot
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
      "[#{@attrs[:l]}, #{@attrs[:u]}]"
    end
  end

  # private
  # def self.var_leq(lhs, rhs)
  #   if lhs.attrs[:l].is_a?(Z3::Expr) ||
  #      lhs.attrs[:u].is_a?(Z3::Expr) ||
  #      rhs.attrs[:l].is_a?(Z3::Expr) ||
  #      rhs.attrs[:u].is_a?(Z3::Expr)
  #     cond = (lhs.attrs[:l] <= rhs.attrs[:u]) & (rhs.attrs[:u] <= lhs.attrs[:u])
  #     if cond.is_a?(Z3::Expr)
  #       read, write = IO.pipe

  #       pid = Process.fork do
  #         read.close
  #         s = Z3::Solver.new
  #         (lhs.asserts + rhs.asserts).each { |a|
  #           if a.is_a?(Z3::Expr)
  #             s.assert a
  #           elsif !a # a is false
  #             raise AbsyntheError, "unexpected concrete value false"
  #           end
  #         }
  #         s.assert cond
  #         Marshal.dump(s.satisfiable?, write)
  #         exit
  #       end

  #       write.close
  #       result = read.read
  #       Process.wait pid
  #       read.close
  #       Marshal.load result
  #     else
  #       cond
  #     end
  #   else
  #     (lhs.attrs[:l] <= rhs.attrs[:u]) && (rhs.attrs[:u] <= lhs.attrs[:u])
  #   end
  # end
end
