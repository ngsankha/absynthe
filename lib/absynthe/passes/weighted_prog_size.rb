require 'ast'

class WeightedSizePass < ::AST::Processor
  attr_reader :size

  def self.prog_size(node)
    visitor = WeightedSizePass.new
    visitor.process(node)
    visitor.size
  end

  def initialize
    @size = 0
  end

  def on_prop(node)
    @size += 5
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end

  alias :on_send :on_prop

  def handler_missing(node)
    @size += 1
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end
end
