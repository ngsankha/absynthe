module Sygus
  class StringLenExtInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[StringLenExt] = self
    extend VarName

    def self.domain
      StringLenExt
    end

    def self.interpret(env, node)
      case node.type
      when :const
        konst = node.children[0]
        case konst
        when AbstractDomain
          konst
        when String, Integer, true, false
          StringLenExt.from(konst)
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
            StringLenExt.bot
          elsif arg0.top? || arg1.top?
            StringLenExt.top
          else
            if arg0.val? && arg1.val?
              StringLenExt.val(arg0.attrs[:val] + arg1.attrs[:val])
            else
              StringLenExt.fresh_var
            end
          end
        when :"str.replace"
          StringLenExt.top
        when :"str.at"
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          if arg0.bot? || arg1.bot?
            StringLenExt.bot
          elsif arg0.top? || arg1.top?
            StringLenExt.top
          else
            StringLenExt.val(Interval.new(0, 1))
          end
        when :"int.to.str"
          arg0 = interpret(env, node.children[1])
          StringLenExt.from(arg0.to_s)
        when :"str.substr"
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          arg2 = interpret(env, node.children[3])
          if arg0.bot? || arg1.bot? || arg2.bot?
            StringLenExt.bot
          elsif arg0.top? || arg1.top? || arg2.top?
            StringLenExt.top
          else
          end

          if arg1.val? && arg2.val?
            StringLenExt.val(Interval.new(
              arg2.attrs[:val] - arg1.attrs[:val] + 1,
              arg2.attrs[:val] - arg1.attrs[:val] + 1))
          elsif arg1.var? || arg2.var?
            StringLenExt.fresh_var
          else
            StringLenExt.top
          end
        when :+
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          if arg0.val? && arg1.val?
            StringLenExt.val(arg0.attrs[:val] + arg1.attrs[:val])
          elsif arg0.var? || arg1.var?
            StringLenExt.fresh_var
          else
            StringLenExt.top
          end
        when :-
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          if arg0.val? && arg1.val?
            StringLenExt.val(arg0.attrs[:val] - arg1.attrs[:val])
          elsif arg0.var? || arg1.var?
            StringLenExt.fresh_var
          else
            StringLenExt.top
          end
        when :"str.len"
          StringLenExt.top
        when :"str.to.int"
          StringLenExt.top
        when :"str.indexof"
          StringLenExt.top
        when :"str.prefixof"
          StringLenExt.top
        when :"str.suffixof"
          StringLenExt.top
        when :"str.contains"
          StringLenExt.top
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
