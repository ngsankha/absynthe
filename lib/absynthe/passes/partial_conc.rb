require 'ast'

class PartialConcretizePass < ::AST::Processor
  def initialize(lang)
    @lang = lang
  end

  def on_partial_conc(node)
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
