module Python
  class PandasRowsInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[PandasRows] = self

    def self.domain
      PandasRows
    end

    def self.interpret(env, node)
      case node.type
      when :const
        konst = node.children[0]
        case konst
        when AbstractDomain
          konst
        when Integer
          domain.val([konst])
        when Symbol
          # assume all environment maps to abstract values
          env[konst]
        else
          raise AbsyntheError, "unexpected constant type"
        end
      when :array
        node.children.reduce(interpret(env, node.children[0])) { |u, n|
          u.union(interpret(env, n))
        }
      when :prop
        recv = interpret(env, node.children[0])
        prop = node.children[1]
        arg  = interpret(env, node.children[2])
        case prop
        when :loc_getitem
          if arg <= recv
            arg
          end
        else
          raise AbsyntheError, "unknown property"
        end
      when :hole
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
