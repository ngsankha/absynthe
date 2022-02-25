class StringSuffix < AbstractDomain
  attr_reader :attrs, :variant

  private_class_method :new

  def initialize(variant, **attrs)
    @variant = variant
    @attrs = attrs
    freeze
  end

  def self.top
    new(:top)
  end

  def self.bot
    new(:bot)
  end

  def self.var(name)
    new(:var, name: name)
  end

  def self.val(suffix, const_str)
    new(:val, suffix: suffix, const_str: const_str)
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

  def <=(rhs)
    raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
    lhs = self
    return true if lhs.var? || rhs.var?
    return true if rhs.top?
    return true if lhs.bot?
    return false if lhs.top?
    return false if rhs.bot?
    lhs.attrs[:suffix].end_with?(rhs.attrs[:suffix])
  end

  def ==(rhs)
    raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
    @variant == rhs.variant && @attrs == rhs.attrs
  end

  def self.from(val)
    case val
    when String
      StringSuffix.val(val, true)
    when Integer, true, false
      StringSuffix.bot
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
        "\"#{@attrs[:suffix]}\""
      else
        @attrs[:suffix]
      end
    end
  end
end
