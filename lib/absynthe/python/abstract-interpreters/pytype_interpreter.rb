module Python
  class PyTypeInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[PyType] = self

    def self.domain
      PyType
    end

    def self.interpret(env, node)
      case node.type
      when :const
        konst = node.children[0]
        case konst
        when AbstractDomain
          konst
        when Integer
          domain.val(RDL::Globals.types[:integer])
        when Symbol
          # assume all environment maps to abstract values
          env[konst]
        else
          raise AbsyntheError, "unexpected constant type"
        end
      when :array
        # TODO(unsound): iterate over all items in the array
        # TODO: handle empty arrays
        item0 = node.children[0]
        v = interpret(env, item0)
        domain.val(RDL::Type::GenericType.new(RDL::Globals.types[:array], RDL::Globals.types[:integer]))
      when :prop
        recv = interpret(env, node.children[0])
        prop = node.children[1]
        arg  = interpret(env, node.children[2])
        meths = RDL::Globals.info.info[recv.attrs[:ty].to_s]
        # TODO: uses only the first type defn
        meth_ty = meths[prop][:type][0]
        # TODO: only one argument
        if arg <= PyType.val(meth_ty.args[0])
          domain.val(meth_ty.ret)
        end
      when :hole
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
