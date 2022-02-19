require 'ast'

class HoleCountPass < ::AST::Processor
  attr_reader :num_holes

  def self.holes(node)
    visitor = HoleCountPass.new
    visitor.process(node)
    visitor.num_holes
  end

  def initialize
    @num_holes = 0
  end

  def on_hole(node)
    @num_holes += 1
    node
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end
end
