class AbstractDomain
  # TODO: fill the template methods
end

module Sygus
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

  class SuffixInterpreter
    def self.interpret(env, node)
      case node.type
      when :const
        konst = node.children[0]
        case konst
        when AbstractDomain
          konst
        when String, Integer, true, false
          StringSuffix.from(konst)
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
          arg1 = interpret(env, node.children[2])

          if arg1.val? && arg1.attrs[:const_str]
            if arg0.val?
              if arg0.attrs[:const_str]
                StringSuffix.val(arg0.attrs[:suffix] + arg1.attrs[:suffix], true)
              else
                StringSuffix.val(arg0.attrs[:suffix] + arg1.attrs[:suffix], false)
              end
            elsif arg0.var?
              arg0
            else
              arg1
            end
          else
            arg1
          end
        when :"str.replace"
          StringSuffix.top
        when :"str.at"
          StringSuffix.top
        when :"int.to.str"
          StringSuffix.top
        when :"str.substr"
          StringSuffix.top
        when :+
          StringSuffix.bot
        when :-
          StringSuffix.bot
        when :"str.len"
          StringSuffix.bot
        when :"str.to.int"
          StringSuffix.bot
        when :"str.indexof"
          StringSuffix.bot
        when :"str.suffixof"
          StringSuffix.bot
        when :"str.suffixof"
          StringSuffix.bot
        when :"str.contains"
          StringSuffix.bot
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
