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
    ty = goal.attrs[:ty]
    interpreter = AbstractInterpreter.interpreter_from(@ctx.domain)
    expanded = []

    # consts

    # vars
    @ctx.init_env.each { |name, val|
      expanded << s(:const, name.to_sym) if val <= goal
    }

    # arrays
    if ty.is_a?(RDL::Type::GenericType) && ty.base == RDL::Globals.types[:array] && ty.params[0] == RDL::Globals.types[:integer]
      expanded << s(:array, s(:const, 0),
                            s(:const, 2),
                            s(:const, 4))
    end
    # props
    RDL::Globals.info.info.each { |cls, mthds|
      next if cls.to_s.include?("RDL::")
      mthds.delete(:__getobj__)
      mthds.each { |mthd, info|
        trecv = RDL::Type::NominalType.new(cls)
        # TODO: using only first defn here
        tmeth = info[:type][0]
        # TODO: comptypes not supported yet. See TypeOperations module in RbSyn for impl
        targs = tmeth.args
        next if targs.any? { |t| t.is_a? RDL::Type::BotType }
        tout = tmeth.ret
        expanded << s(:prop, s(:hole, nil, PyType.val(trecv)), mthd, *targs.map { |t| s(:hole, nil, PyType.val(t)) })
      }
    }

    # funcs

    @expand_map << expanded.size
    s(:filled_hole, goal, *expanded)
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end