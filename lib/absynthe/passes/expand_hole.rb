require 'ast'

class ExpandHolePass < ::AST::Processor
  attr_reader :expand_map

  def initialize(lang)
    @lang = lang
    @expand_map = []
  end

  def on_hole(node)
    expanded = @lang.rules[node.children[0]]
    @expand_map << expanded.size
    s(:filled_hole, *expanded)
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
