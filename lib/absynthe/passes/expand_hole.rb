require 'ast'

class ExpandHolePass < ::AST::Processor
  attr_reader :expand_map

  def initialize(ctx, lang)
    @ctx = ctx
    @lang = lang
    @expand_map = []
  end

  def on_hole(node)
    goal = node.children[1]
    rules = @lang.rules[node.children[0]]
    expanded = rules.map { |r|
      case r
      when Terminal
        if r.name.is_a? Symbol
          if @lang.rules.key?(r.name)
            s(:hole, r.name, goal)
          else
            s(:const, r.name)
          end
        else
          s(:const, r.name)
        end
      when NonTerminal
        args = r.args.map { |n| s(:hole, n, @ctx.domain.var(:x)) }
        s(:send, r.name, *args)
      else
        raise AbsyntheError, "unexpected class #{r}"
      end
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
