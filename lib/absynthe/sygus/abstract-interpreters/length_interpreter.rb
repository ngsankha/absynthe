# Not recommended! Use StringLenExtInterpreter

module Sygus
  class StringLengthInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[StringLength] = self
    extend VarName

    def self.domain
      StringLength
    end

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

          if arg0.bot? || arg1.bot?
            StringLength.bot
          elsif arg0.top? || arg1.top?
            StringLength.top
          else
            if arg0.val? && arg1.val?
              StringLength.val(
                arg0.attrs[:l] + arg1.attrs[:l],
                arg0.attrs[:u] + arg1.attrs[:u])
            else
              StringLength.fresh_var
            end
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
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
