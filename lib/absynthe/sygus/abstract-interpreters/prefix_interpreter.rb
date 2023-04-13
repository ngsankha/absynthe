# String prefix abstract intrepreter

module Sygus
  class PrefixInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[StringPrefix] = self

    def self.domain
      StringPrefix
    end

    def self.interpret(env, node)
      case node.type
      # constants return the abstract value directly
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
      # function calls
      when :send
        case node.children[0]
        # string concat
        when :"str.++"
          arg0 = interpret(env, node.children[1])

          if arg0.val? && arg0.attrs[:const_str]
            arg1 = interpret(env, node.children[2])
            if arg1.val?
              if arg1.attrs[:const_str]
                # if both strings are constants (ie prefix and full string are
                # same), the prefix of the final string is the concat of both strings
                StringPrefix.val(arg0.attrs[:prefix] + arg1.attrs[:prefix], true)
              else
                # if the above doesn't hold for 2nd string, the prefix is the concat,
                # but this time it is prefix and not the full string
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
        # everything else is top or bottom
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
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
