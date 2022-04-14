# This is a special case: it combines individual domains. Hence it redefines
# the <= method. It does not need the glb and lub as those are only needed from
# the generic <= method for base domains.
class ProductDomain < AbstractDomain
  attr_reader :domains, :variant

  private_class_method :new

  @@classes = [
    StringLength,
    StringPrefix,
    StringSuffix,
    StringLenExt
  ]

  def initialize(variant, domains)
    @variant = variant
    @domains = {}
    domains.each { |v|
      raise AbsyntheError, "only AbstractDomain allowed" unless v.is_a? AbstractDomain
      @domains[v.class] = v
    }
  end

  def solvable?
    @domains.values.any? { |v| v.solvable? }
  end

  def self.top
    new(:top, @@classes.map { |k| k.top })
  end

  def self.bot
    new(:bot, @@classes.map { |k| k.bot })
  end

  def self.var(name)
    new(:var, @@classes.map { |k| k.var(name) })
  end

  def self.val(*domains)
    new(:val, domains)
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
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
    lhs = self
    # puts "lhs: #{lhs.inspect}"
    # puts "rhs: #{rhs.inspect}"
    lhs.domains.all? { |k, v|
      ind_rhs = rhs.domains[k]
      if ind_rhs.nil?
        true
      else
        v <= ind_rhs
      end
    }
  end

  def ==(rhs)
    raise AbsyntheError, "Unexpected type error" if rhs.class != self.class
    @variant == rhs.variant && @domains == rhs.domains
  end

  def self.from(val)
    ProductDomain.val(@@classes.map { |klass| klass.from(val) })
  end

  def to_s
    if top?
      "⊤"
    elsif bot?
      "⊥"
    else
      @domains.map { |k, v| "(#{v.to_s} :: #{k.to_s})" }.join(" x ")
    end
  end
end
