require 'ast'

class ProgHeightPass < ::AST::Processor
  attr_reader :height

  def self.prog_height(node)
    visitor = ProgHeightPass.new
    visitor.process(node)
    visitor.height
  end

  def initialize
    @height = 0
  end

  def handler_missing(node)
    @height = node.children.map { |k|
      if k.is_a?(Parser::AST::Node)
        ProgHeightPass.prog_height(k) + 1
      else
        1
      end
    }.max

    nil
  end
end
