# Solver aided string length domain interpreter

module Sygus
  class StringLenExtInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[StringLenExt] = self
    extend VarName

    def self.domain
      StringLenExt
    end

    def self.interpret(env, node)
      case node.type
      # constants return the abstract value
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
      # semantics of individual sygus string functions
      when :send
        case node.children[0]
        # symbolically concatenate 2 strings lengths
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
        # top, since there is no way to represent this in string length
        when :"str.replace"
          StringLenExt.top
        # if the lookup index is within string length, the final length is 1 else 0
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
        # if the indexes are within bounds, the length is end - start indexes
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
        # symbolically add 2 numbers
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
        # symbolically subtract 2 numbers
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
        # we are already in string length, return the same
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
