module Sygus
  class StringLength < AbstractDomain
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

    def self.val(l, u)
      new(:val, l: l, u: u)
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
      lhs.attrs[:l] <= rhs.attrs[:l] && rhs.attrs[:u] <= lhs.attrs[:u]
    end

    def ==(rhs)
      raise AbsyntheError, "Unexptected type error" if rhs.class != self.class
      @variant == rhs.variant && @attrs == rhs.attrs
    end

    def self.from(val)
      case val
      when String
        StringLength.val(val.length, val.length)
      when Integer, true, false
        StringLength.bot
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
        "[#{@attrs[:l]}, #{@attrs[:u]}]"
      end
    end
  end

  class StringLengthInterpreter
    def self.interpret(env, node)
      case node.type
      when :const
        konst = node.children[0]
        case konst
        when AbstractDomain
          konst
        when String, Integer, true, false
          StringLength.from(konst)
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

          if arg0.val? && arg1.val?
            StringLength.val(
              arg0.attrs[:l] + arg1.attrs[:l],
              arg0.attrs[:u] + arg1.attrs[:u])
          elsif arg0.bot? || arg1.bot?
            StringLength.bot
          elsif arg0.var? || arg1.var?
            # TODO: needs a fresh variable name here
            StringLength.var(:x)
          else
            StringLength.top
          end
        when :"str.replace"
          StringLength.top
        when :"str.at"
          arg0 = interpret(env, node.children[1])
          if arg0.bot?
            arg0
          else
            StringLength.val(0, 1)
          end
        when :"int.to.str"
          StringLength.top
        when :"str.substr"
          arg0 = interpret(env, node.children[1])
          if arg0.val?
            StringLength.val(0, arg0.attrs[:u])
          else
            arg0
          end
        when :+
          StringLength.bot
        when :-
          StringLength.bot
        when :"str.len"
          StringLength.bot
        when :"str.to.int"
          StringLength.bot
        when :"str.indexof"
          StringLength.bot
        when :"str.prefixof"
          StringLength.bot
        when :"str.suffixof"
          StringLength.bot
        when :"str.contains"
          StringLength.bot
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
