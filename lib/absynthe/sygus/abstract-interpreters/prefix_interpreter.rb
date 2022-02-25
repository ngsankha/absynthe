module Sygus
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

          if arg0.val? && arg0.attrs[:const_str]
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
