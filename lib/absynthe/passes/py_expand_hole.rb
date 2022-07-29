require 'ast'
require 'pry'
require 'pry-byebug'

class ExpandHolePass < ::AST::Processor
  attr_reader :expand_map
  include VarName

  def initialize(ctx, lang)
    @ctx = ctx
    @expand_map = []
  end

  def on_hole(node)
    goal = node.children[1]
    ty = goal.domains[PyType].attrs[:ty]
    rownums = goal.domains[PandasRows]
    interpreter = AbstractInterpreter.interpreter_from(@ctx.domain)
    expanded = []

    # consts

    # vars
    @ctx.init_env.each { |name, val|
      expanded << s(:const, name.to_sym) if val <= goal
    }

    # arrays
    if ty.is_a?(RDL::Type::GenericType) && ty.base == RDL::Globals.types[:array] && ty.params[0] == RDL::Globals.types[:integer]
      if rownums.var?
        expanded << s(:array,
          *rownums.glb.attrs[:rownums]
            .to_a.map { |n| s(:const, n) })
      end
    end

    # props
    RDL::Globals.info.info.each { |cls, mthds|
      next if cls.to_s.include?("RDL::")
      mthds.delete(:__getobj__)
      mthds.each { |mthd, info|
        next unless mthd.to_s.end_with? "_getitem"
        trecv = RDL::Type::NominalType.new(cls)
        # TODO: using only first defn here
        tmeth = info[:type][0]
        # TODO: comptypes not supported yet. See TypeOperations module in RbSyn for impl
        targs = tmeth.args
        next if targs.any? { |t| t.is_a? RDL::Type::BotType }
        tout = tmeth.ret
        expanded << s(:prop,
                      s(:hole, nil, ProductDomain.val(PyType.val(trecv), PandasRows.fresh_var)),
                      mthd,
                      *targs.map { |t|
                        s(:hole, nil, ProductDomain.val(PyType.val(t), PandasRows.fresh_var))
                      })
      }
    }

    # funcs
    RDL::Globals.info.info.each { |cls, mthds|
      next if cls.to_s.include?("RDL::")
      mthds.delete(:__getobj__)
      mthds.each { |mthd, info|
        next if mthd.to_s.end_with? "_getitem"
        trecv = RDL::Type::NominalType.new(cls)
        # TODO: using only first defn here
        tmeth = info[:type][0]
        # puts tmeth.inspect
        # TODO: comptypes not supported yet. See TypeOperations module in RbSyn for impl
        targs = tmeth.args
        arg_terms = targs.map { |arg|
          if arg.is_a? RDL::Type::NominalType
            s(:hole, nil, ProductDomain.val(PyType.val(arg), PandasRows.fresh_var))
          elsif arg.is_a? RDL::Type::FiniteHashType
            s(:hash, *arg.elts.map { |k, v|
              s(:key, k, s(:hole, nil, ProductDomain.val(PyType.val(v), PandasRows.fresh_var)))
              })
          else
            raise AbsyntheError, "unexpected type"
          end
        }
        next if targs.any? { |t| t.is_a? RDL::Type::BotType }
        tout = tmeth.ret
        expanded << s(:send,
                      s(:hole, nil, ProductDomain.val(PyType.val(trecv), PandasRows.fresh_var)),
                      mthd,
                      *arg_terms)
      }
    }

    @expand_map << expanded.size
    s(:filled_hole, goal, *expanded)
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
