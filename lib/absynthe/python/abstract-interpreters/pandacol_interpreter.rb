# The abstract interpter for Pandas methods defined using the Pandas columns domain
module Python
  class PandasColsInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[PandasCols] = self

    def self.domain
      PandasCols
    end

    def self.interpret(env, node)
      case node.type
      # constants and variables return the abstract value
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
        when NUnique
          domain.bot
        else
          raise AbsyntheError, "unexpected constant type #{konst.inspect}"
        end
      # arrays return the union of each abstract value
      when :array
        node.children.reduce(interpret(env, node.children[0])) { |u, n|
          u.union(interpret(env, n))
        }
      # properties are .loc[], [], .T, .values
      # these are treated like a method call
      when :prop
        recv = interpret(env, node.children[0])
        prop = node.children[1]
        case prop
        when :loc_getitem
          arg  = interpret(env, node.children[2])
          arg
        when :__getitem__
          domain.top
        when :T
          domain.top
        when :values
          domain.top
        else
          raise AbsyntheError, "unknown property #{prop}"
        end
      # each method call is handled as it's own case for each supported method
      # some methods returns the abstract value of the receiver of the method call, some return top, etc
      when :send
        recv = interpret(env, node.children[0])
        meth = node.children[1]
        case meth
        when :apply
          recv
        when :astype
          recv
        when :combine_first
          arg1  = interpret(env, node.children[2])
          recv.union(arg1)
        when :cumsum
          recv
        when :div
          recv
        when :dropna
          recv
        when :fillna
          recv
        when :groupby
          domain.top
        when :isin
          recv
        when :mean
          domain.top
        when :melt
          domain.top
        when :merge
          domain.top
        when :pivot
          domain.top
        when :pivot_table
          domain.top
        when :query
          recv
        when :reset_index
          domain.top
        when :set_index
          domain.top
        when :size
          domain.top
        when :sort_values
          recv
        when :stack
          domain.top
        when :sum
          recv
        when :unstack
          domain.top
        when :xs
          domain.top
        else
          raise AbsyntheError, "unknown method #{meth}"
        end
      # holes returns the abstract values projected into the Pandas Columns domain
      when :hole
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
