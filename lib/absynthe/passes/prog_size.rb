require 'ast'

# Counts the number of nodes in an AST

class ProgSizePass < ::AST::Processor
  attr_reader :size

  def self.prog_size(node)
    visitor = ProgSizePass.new
    visitor.process(node)
    visitor.size
  end

  def initialize
    @size = 0
  end

  def handler_missing(node)
    @size += 1
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end
end
