module Sygus
  class ProblemSpec
    attr_reader :func_name, :args, :ret_type, :lang, :constraints

    def initialize(ast)
      @constraints = []
      eval(ast)
    end

    def test_prog(prog)
      begin
        @constraints.all? { |val|
          Sygus::interpret({:name => val[0]}, prog) == val[1]
        }
      rescue
        false
      end
    end

    private
    def eval(ast)
      ast.each { |n| eval_node(n) }
    end

    def eval_productions(prod, type)
      prod.map { |p|
        if p.is_a? Array
          NonTerminal.new(p[0], type, p[1..])
        else
          Terminal.new(p, type)
        end
      }
    end

    def eval_lang_rule(rule)
      name = rule[0]
      type = rule[1]
      prods = eval_productions(rule[2], type)
      [name, prods]
    end

    def eval_lang_spec(lang)
      l = Language.new
      lang.each { |r|
        name, prods = eval_lang_rule(r)
        l.add_rule(name, prods)
      }
      l
    end

    def get_arg(node)
      case node[0]
      when @func_name
        node[1]
      else
        raise AbsyntheError, "expected function name to be in language spec"
      end
    end

    def eval_constraint(node)
      case node[0]
      when :"="
        [get_arg(node[1]), node[2]]
      else
        raise AbsyntheError, "unexpected constraint"
      end
    end

    def eval_node(node)
      case node[0]
      when :"set-logic"
        return
      when :"synth-fun"
        @func_name = node[1]
        @args = node[2]
        @ret_type = node[3]
        @lang = eval_lang_spec(node[4])
      when :"declare-var"
        return
      when :constraint
        @constraints << eval_constraint(node[1])
      when :"check-synth"
        return
      else
        raise AbsyntheError, "unexpected node #{node[0]}"
      end
    end
  end
end
