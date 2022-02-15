class AbstractDomain
  def self.top
    raise AbsyntheError, "Not implemented!"
  end

  def self.bot
    raise AbsyntheError, "Not implemented!"
  end

  def <=(rhs)
    raise AbsyntheError, "Not implemented!"
  end

  def ==(rhs)
    raise AbsyntheError, "Not implemented!"
  end

  def top?
    raise AbsyntheError, "Not implemented!"
  end

  def bot?
    raise AbsyntheError, "Not implemented!"
  end

  def self.from(val)
    raise AbsyntheError, "Not implemented!"
  end

  def hash
    raise AbsyntheError, "Not implemented!"
  end
end

module Sygus
  class StringPrefix < AbstractDomain
    attr_reader :prefix

    def initialize(prefix)
      @prefix = prefix
    end

    def self.top
      StringPrefix.new("")
    end

    def self.bot
      StringPrefix.new(-1)
    end

    def top?
      @prefix == ""
    end

    def bot?
      @prefix == -1
    end

    def <=(rhs)
      raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
      lhs = self
      return true if rhs.top?
      return true if lhs.bot?
      lhs.prefix.start_with?(rhs.prefix)
    end

    def ==(rhs)
      raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
      @prefix == rhs.prefix
    end

    def self.from(val)
      case val
      when String, Symbol
        StringPrefix.new(val)
      when Integer, true, false
        StringPrefix::bot
      else
        raise AbsyntheError, "unexpected type"
      end
    end

    def to_s
      if top?
        "⊤"
      elsif bot?
        "⊥"
      else
        @prefix
      end
    end

    def hash
      @prefix.hash
    end
  end

  class PrefixInterpreter
    def self.interpret(env, node)
      case node.type
      when :const
        konst = node.children[0]
        case konst
        when AbstractDomain
          konst
        when String, Integer, true, false
          StringPrefix.from(konst)
        when Symbol
          # assume all environment maps to abstract values
          env[konst]
        else
          raise AbsyntheError, "unexpected constant type"
        end
      when :send
        case node.children[0]
        when :"str.++"
          arg0 = interpret(env, node.children[1])
          arg0
        when :"str.replace"
          StringPrefix.top
        when :"str.at"
          StringPrefix.top
        when :"int.to.str"
          StringPrefix.top
        when :"str.substr"
          StringPrefix.top
        when :+
          StringPrefix.bot
        when :-
          StringPrefix.bot
        when :"str.len"
          StringPrefix.bot
        when :"str.to.int"
          StringPrefix.bot
        when :"str.indexof"
          StringPrefix.bot
        when :"str.prefixof"
          StringPrefix.bot
        when :"str.suffixof"
          StringPrefix.bot
        when :"str.contains"
          StringPrefix.bot
        else
          raise AbsyntheError, "unexpected AST node"
        end
      end
    end
  end
end
