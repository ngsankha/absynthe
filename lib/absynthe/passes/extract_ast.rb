require 'ast'

class ExtractASTPass < ::AST::Processor
  def initialize(selection)
    @selection = selection
  end

  def on_filled_hole(node)
    # first node is the goal abstract value
    idx = @selection.shift + 1
    node.children[idx]
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
