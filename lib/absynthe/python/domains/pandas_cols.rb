require 'set'

class PandasCols < AbstractDomain
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

  def self.val(name)
    new(:val, name: name)
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
    lhs.attrs[:name] == rhs.attrs[:name]
  end

  def var_leq(lhs, rhs)
    return false
  end

  def ==(rhs)
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
    @variant == rhs.variant && @attrs == rhs.attrs
  end

  def self.from(val)
    raise AbsyntheError, "unexpected type"
  end

  def to_s
    if top?
      "⊤"
    elsif bot?
      "⊥"
    elsif var?
      "?#{@attrs[:name]}"
    else
      raise AbsyntheError, "Unexpected!"
    end
  end

  def union(other)
    if bot? && other.bot?
      PandasCols.bot
    # elsif val? && other.val?
    #   PandasCols.val(lhs.attrs[:cols].union(rhs.attrs[:cols]))
    else
      PandasCols.top
    end
  end
end
