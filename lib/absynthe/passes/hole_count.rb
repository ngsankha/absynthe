require 'ast'

# Counts the number of holes and variables in an AST

class HoleCountPass < ::AST::Processor
  attr_reader :num_holes, :num_depholes, :num_var

  def self.total_holes(node)
    visitor = HoleCountPass.new
    visitor.process(node)
    visitor.num_holes + visitor.num_depholes
  end

  def initialize
    @num_holes = 0
    @num_depholes = 0
    @num_var = 0
  end

  def on_hole(node)
    @num_holes += 1
    node
  end

  def on_dephole(node)
    @num_depholes += 1
    node
  end

  def on_const(node)
    @num_var += 1 if node.children[0].is_a? Symbol
    node
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end
end
