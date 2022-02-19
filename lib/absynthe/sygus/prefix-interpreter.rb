class AbstractDomain
  # TODO: fill the template methods
end

module Sygus
  class StringPrefix < AbstractDomain
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

    def <=(rhs)
      raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
      lhs = self
      return true if lhs.var? || rhs.var?
      return true if rhs.top?
      return true if lhs.bot?
      return false if lhs.top?
      return false if rhs.bot?
      lhs.attrs[:prefix].start_with?(rhs.attrs[:prefix])
    end

    def ==(rhs)
      raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
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

          if arg0.val?
            arg1 = interpret(env, node.children[2])
            if arg1.val?
              if arg1.attrs[:const_str]
                StringPrefix.val(arg0.attrs[:prefix] + arg1.attrs[:prefix], true)
              else
                StringPrefix.val(arg0.attrs[:prefix] + arg1.attrs[:prefix], false)
              end
            elsif arg1.var?
              arg1
            else
              arg0
            end
          else
            arg0
          end
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
      when :hole
        node.children[1]
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
