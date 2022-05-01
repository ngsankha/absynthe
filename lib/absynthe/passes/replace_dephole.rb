require 'ast'

class ReplaceDepholePass < ::AST::Processor

  def initialize(ctx, count)
    @count = count
    @ctx = ctx
  end

  def on_dephole(node)
    if @count > 1
      @count -= 1
      s(:hole, node.children[0], @ctx.domain.fresh_var)
    else
      unless Globals.prev_model.size == 1
        # TODO: add a forall to handle quantified variables from the arguments
        s(:hole, node.children[0], @ctx.domain.fresh_var)
      else
        # puts Globals.prev_model.values.first.to_i
        s(:hole, node.children[0], @ctx.domain.val(Globals.prev_model.values.first.to_i))
      end
    end
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
