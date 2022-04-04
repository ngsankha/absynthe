class StringSuffix < AbstractDomain
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

  def self.var(name, length = nil)
    result = new(:var, name: name, length: length)
    result.glb = @@bot
    result.lub = @@top
    result
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

  def val_leq(lhs, rhs)
    lhs.attrs[:suffix].end_with?(rhs.attrs[:suffix])
  end

  def var_leq(lhs, rhs)
    if lhs.attrs[:name] == rhs.attrs[:name]
      return leq_nil(lhs.attrs[:length], rhs.attrs[:length])
    else
      return false
    end
  end

  # def <=(rhs)
  #   raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
  #   lhs = self
  #   return true if rhs.top?
  #   return true if lhs.bot?

  #   return lhs.attrs[:suffix].end_with?(rhs.attrs[:suffix]) if (lhs.val? && rhs.val?)

  #   if lhs.var? && rhs.var?
  #     if lhs.attrs[:name] == rhs.attrs[:name]
  #       return leq_nil(lhs.attrs[:length], rhs.attrs[:length])
  #     else
  #       return true
  #     end
  #   end

  #   return false if lhs.top?
  #   return false if rhs.bot?

  #   return false
  # end

  def ==(rhs)
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
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
      if @attrs[:length]
        "?#{@attrs[:name]}[#{@attrs[:length]}]"
      else
        "?#{@attrs[:name]}"
      end
    else
      if @attrs[:const_str]
        "\"#{@attrs[:suffix]}\""
      else
        @attrs[:suffix]
      end
    end
  end

  private
  def leq_nil(lhs, rhs)
    if lhs && rhs
      lhs >= rhs
    elsif lhs
      false
    elsif rhs
      true
    else
      true
    end
  end
end
