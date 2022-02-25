module Sygus
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
