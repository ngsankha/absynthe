require 'ast'

# Counds the number of functions or property calls in a Python AST
# This is the number of (:send ...) and (:prop ...) nodes in the AST

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

  def on_prop(node)
    @size += 1
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end

  alias :on_send :on_prop

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
  end
end
