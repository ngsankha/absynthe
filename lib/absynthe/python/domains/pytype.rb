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

  def promote
    if @attrs[:ty].is_a?(RDL::Type::GenericType) &&
       @attrs[:ty].base == RDL::Globals.types[:array]
      ty = RDL::Type::GenericType.new(
        RDL::Globals.types[:array],
        promote_impl(@attrs[:ty].params[0]))
      return PyType.val(ty)
    end

    self
  end

  def promote_impl(rdl_ty)
    if rdl_ty.is_a?(RDL::Type::UnionType)
      if rdl_ty.types.all? { |ty|
        ty.is_a?(RDL::Type::SingletonType) &&
        ty.val.is_a?(Integer) }
        return RDL::Globals.types[:integer]
      end
    elsif rdl_ty.is_a?(RDL::Type::SingletonType) && rdl_ty.val.is_a?(Integer)
      return RDL::Globals.types[:integer]
    end

    rdl_ty
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
    if lhs.attrs[:ty].is_a?(RDL::Type::FiniteHashType) &&
       rhs.attrs[:ty].is_a?(RDL::Type::FiniteHashType)
      # treat all keys as optional
      lhs.attrs[:ty].elts.keys.all? { |k|
        rhs.attrs[:ty].elts.key?(k) &&
        lhs.attrs[:ty].elts[k] <= rhs.attrs[:ty].elts[k]
      }
    else
      lhs.attrs[:ty] <= rhs.attrs[:ty]
    end
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
