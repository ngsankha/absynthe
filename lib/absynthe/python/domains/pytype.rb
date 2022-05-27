class PyType < AbstractDomain
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
    raise AbsyntheError, "unimplemented"
  end

  def self.val(ty)
    new(:val, ty: ty)
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
    lhs.attrs[:ty] <= rhs.attrs[:ty]
  end

  def var_leq(lhs, rhs)
    raise AbsyntheError, "unimplemented"
  end

  def ==(rhs)
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
    @variant == rhs.variant && @attrs == rhs.attrs
  end

  def self.from(val)
    raise AbsyntheError, "unimplemented"
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
      @attrs[:ty].to_s
    end
  end
end
