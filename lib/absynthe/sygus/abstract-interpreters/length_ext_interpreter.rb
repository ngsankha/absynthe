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
            res = StringLenExt.var(arg0.attrs[:val] + arg1.attrs[:val])
            res.asserts.push(*arg0.asserts)
            res.asserts.push(*arg1.asserts)
            res
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
            cond = arg0.attrs[:val] > arg1.attrs[:val]
            if cond == true
              StringLenExt.val(1)
            elsif cond == false
              StringLenExt.val(0)
            else # LazyZ3::Z3Node
              res = StringLenExt.fresh_var
              res.asserts << ((res.attrs[:val] == 0) | (res.attrs[:val] == 1))
              res
            end
          end
        when :"int.to.str"
          StringLenExt.top
        when :"str.substr"
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          arg2 = interpret(env, node.children[3])
          if arg1.bot? || arg2.bot?
            StringLenExt.bot
          elsif arg1.top? || arg2.top?
            StringLenExt.top
          else
            res = StringLenExt.val(arg2.attrs[:val] - arg1.attrs[:val])
            if !(arg0.top? || arg0.bot?)
              res.asserts.push(arg0.attrs[:val] >= arg2.attrs[:val])
            end
            res.asserts.push(*arg1.asserts)
            res.asserts.push(*arg2.asserts)
            res
          end
        when :+
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          if arg0.top? || arg1.top?
            StringLenExt.top
          elsif arg0.bot? || arg1.bot?
            StringLenExt.bot
          else
            res = StringLenExt.val(arg0.attrs[:val] + arg1.attrs[:val])
            res.asserts.push(*arg0.asserts)
            res.asserts.push(*arg1.asserts)
            res
          end
        when :-
          arg0 = interpret(env, node.children[1])
          arg1 = interpret(env, node.children[2])
          if arg0.top? || arg1.top?
            StringLenExt.top
          elsif arg0.bot? || arg1.bot?
            StringLenExt.bot
          else
            res = StringLenExt.val(arg0.attrs[:val] - arg1.attrs[:val])
            res.asserts.push(*arg0.asserts)
            res.asserts.push(*arg1.asserts)
            res.asserts.push(res.attrs[:val] > 0)
            res
          end
        when :"str.len"
          arg0 = interpret(env, node.children[1])
          if !(arg0.top? || arg0.bot?)
            arg0.asserts.push(arg0.attrs[:val] > 0)
          end
          arg0
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
      when :dephole
        eval_dephole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
