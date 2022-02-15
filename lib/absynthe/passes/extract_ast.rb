require 'ast'

class ExtractASTPass < ::AST::Processor
  def initialize(ctx, selection, lang)
    @ctx = ctx
    @selection = selection
    @lang = lang
  end

  def on_filled_hole(node)
    idx = @selection.shift
    new_node = node.children[idx]
    case new_node
    when Terminal
      if new_node.name.is_a? Symbol
        if @lang.rules.key?(new_node.name)
          s(:hole, new_node.name, @ctx.domain.top)
        else
          s(:const, new_node.name)
        end
      else
        s(:const, new_node.name)
      end
    when NonTerminal
      s(:send, new_node.name, *new_node.args.map { |n| s(:hole, n, @ctx.domain.top) })
    else
      raise AbsyntheError, "unexpected class #{new_node}"
    end
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
