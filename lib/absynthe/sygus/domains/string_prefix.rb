# String Prefix abstract domain
# Keeps track of a prefix of the string, and if that string is identical to the stored prefix or not
# The latter provides more precision in string concat operations

class StringPrefix < AbstractDomain
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

  def self.val(prefix, const_str)
    new(:val, prefix: prefix, const_str: const_str)
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

  # <= checks if one strings starts with the other string
  def val_leq(lhs, rhs)
    lhs.attrs[:prefix].start_with?(rhs.attrs[:prefix])
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
      StringPrefix.val(val, true)
    when Integer, true, false
      StringPrefix.bot
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
      if @attrs[:const_str]
        "\"#{@attrs[:prefix]}\""
      else
        @attrs[:prefix]
      end
    end
  end
end
