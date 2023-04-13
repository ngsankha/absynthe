module Sygus

  # A SyGuS problem specification

  class ProblemSpec
    attr_reader :func_name, :args, :ret_type, :lang, :constraints, :init_env

    def initialize(ast)
      @constraints = []
      @init_env = {}
      eval(ast)
    end

    # runs a program against a given SyGuS input output examples
    def test_prog(prog)
      begin
        @constraints.all? { |input, output|
          env = @init_env.dup
          args.zip(input).each { |node, argval|
            arg_name = node[0]
            env[arg_name] = argval
          }
          Sygus::interpret(env, prog) == output
        }
      rescue
        false
      end
    end

    private
    # all eval* methods below are used to parse the SyGuS specfication file to
    # load it into the Absynthe internal representation
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
        node[1..]
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
        varname = node[1]
        vartype = node[2]
        @init_env[varname] = vartype
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
