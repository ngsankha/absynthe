require 'ast'
require 'pry'
require 'pry-byebug'

class ExpandHolePass < ::AST::Processor
  attr_reader :expand_map
  include VarName

  def initialize(ctx, lang)
    @ctx = ctx
    @lang = lang
    @expand_map = []
  end

  def on_hole(node)
    goal = node.children[1]
    rules = @lang.rules[node.children[0]]
    interpreter = AbstractInterpreter.interpreter_from(@ctx.domain)
    expanded = rules.map { |r|
      case r
      when Terminal
        if r.name.is_a? Symbol
          if @lang.rules.key?(r.name)
            s(:hole, r.name, goal)
          else
            s(:const, r.name)
          end
        else
          s(:const, r.name)
        end
      when NonTerminal
        args = r.args.map { |n| s(:hole, n, @ctx.domain.fresh_var) }
        # create dependent holes here
        @ctx.domain.replace_dep_hole! r.name, args
        s(:send, r.name, *args)
      else
        raise AbsyntheError, "unexpected class #{r}"
      end
    }.compact

    expanded.push(*@ctx.cache[node.children[0]]) if @ctx.cache.size != 0

    @expand_map << expanded.size
    s(:filled_hole, goal, *expanded)
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
