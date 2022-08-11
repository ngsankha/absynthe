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
          domain.val(RDL::Type::SingletonType.new(konst))
        when String
          # domain.val(RDL::Globals.types[:string])
          domain.val(RDL::Type::PreciseStringType.new(konst))
        when NUnique, PyInt
          domain.val(RDL::Type::NominalType.new(konst.class))
        when Symbol
          # assume all environment maps to abstract values
          env[konst]
        when true
          domain.val(RDL::Globals.types[:true])
        when false
          domain.val(RDL::Globals.types[:false])
        else
          raise AbsyntheError, "unexpected constant type #{konst}"
        end
      when :key
        # warning: does not return an abstract domain!!
        v = interpret(env, node.children[1])
        [node.children[0], v.attrs[:ty]]
      when :hash
        PyType.val(RDL::Type::FiniteHashType.new(
          node.children.map { |elt| interpret(env, elt)}
            .to_h, nil))
      when :array
        # TODO(unsound): iterate over all items in the array
        # TODO: handle empty arrays
        item0 = node.children[0]
        v = interpret(env, item0)
        node.children[1..].each { |k| v = domain.val(RDL::Type::UnionType.new(v.attrs[:ty], interpret(env, k).attrs[:ty])) }
        domain.val(RDL::Type::GenericType.new(RDL::Globals.types[:array], v.attrs[:ty].canonical))
      when :prop, :send
        recv = interpret(env, node.children[0])
        meth_name = node.children[1]
        args = node.children[2..].map { |n|
          interpret(env, n)
        }

        trecv = recv.attrs[:ty]
        if trecv.is_a? RDL::Type::GenericType
          meths = RDL::Globals.info.info[trecv.base.to_s]
        elsif trecv.is_a? RDL::Type::NominalType
          meths = RDL::Globals.info.info[trecv.to_s]
        else
          raise AbsyntheError, "unhandled type #{recv}"
        end

        ret_ty = domain.top

        meths[meth_name][:type].filter { |ty|
          ty.args.size == args.size
        }.each { |meth_ty|
          tc = args.map.with_index { |arg, i|
            res = arg <= PyType.val(meth_ty.args[i])
            res = arg.promote <= PyType.val(meth_ty.args[i]) unless res
            res
          }.all?

          if tc
            if meth_ty.ret.is_a? RDL::Type::VarType
              # assume trecv is GenericType
              params = RDL::Wrap.get_type_params(trecv.base.to_s)[0]
              idx = params.index(meth_ty.ret.name)
              raise RbSynError, "unexpected" if idx.nil?
              ret_ty = domain.val(trecv.params[idx])
            else
              ret_ty = domain.val(meth_ty.ret)
            end
            break
          end
        }

        # puts "===="
        # puts node.children[0] if ret_ty.top?
        # puts node.children[1] if ret_ty.top?
        # puts node.children[2] if ret_ty.top?
        # puts args if ret_ty.top?
        # puts meths[meth_name][:type][0].args if ret_ty.top?
        # puts "==> #{args[0] <= PyType.val(meths[meth_name][:type][0].args[0])}" if ret_ty.top?

        ret_ty
      when :hole
        eval_hole(node)
      else
        raise AbsyntheError, "unexpected AST node #{node.type}"
      end
    end
  end
end
