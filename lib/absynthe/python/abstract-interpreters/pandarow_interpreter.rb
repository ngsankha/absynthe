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
          raise AbsyntheError, "unknown property #{prop}"
        end
      when :send
        recv = interpret(env, node.children[0])
        meth = node.children[1]
        arg  = interpret(env, node.children[2])
        puts arg.inspect
        case meth
        when :xs
          return PandasRows.top if arg.top?
          return PandasRows.bot if arg.bot?
          return arg if arg.var? # not correct
          raise AbsyntheError, "expected multiindex" unless arg.first.is_a?(Array)
          index = {}
          arg.attrs[:rownums].each { |kv|
            unless index.key?(kv[0])
              index[kv[0]] = [kv[1]]
            else
              index[kv[0]] << kv[1]
            end
          }
        else
          raise AbsyntheError, "unknown method #{meth}"
        end
      when :hole
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
