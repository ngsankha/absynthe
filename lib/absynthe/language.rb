class Terminal
  attr_reader :name, :type

  def initialize(name, type)
    @name = name
    @type = type
  end
end

class NonTerminal
  attr_reader :name, :type, :args

  def initialize(name, type, args)
    @name = name
    @type = type
    @args = args
  end
end

class Language
  attr_reader :rules

  def initialize
    @rules = {}
  end

  def add_rule(name, prods)
    @rules[name] = prods
  end
end
