class TemplateInfer

  def initialize(ctx, constraints, args)
    @ctx = ctx
    @constraints = constraints
    @args = args
  end

  def infer
    res = nil
    @args.each { |name, type|
      # 2 examples where we use test with predicates as an optimization
      res = check_predicate(
            s(:send, :"str.suffixof",
              s(:const, :out),
              s(:const, name)),
            s(:send, :"str.substr",
              s(:const, name),
              s(:hole, :ntInt, @ctx.domain.fresh_var),
              s(:send, :"str.len", s(:const, name))))

      res ||= check_predicate(
              s(:send, :"str.contains",
                s(:const, :out),
                s(:const, name)),
              s(:send, :"str.substr",
                s(:const, name),
                s(:hole, :ntInt, @ctx.domain.fresh_var),
                s(:hole, :ntInt, @ctx.domain.fresh_var)))
    }
    res
  end

  # utility method that tests using the predicate `pred` and if true returns a `template`
  def check_predicate(pred, template)
    res = @constraints.all? { |inp, out|
      env = @ctx.init_env.dup
      @args.zip(inp).each { |node, argval|
        arg_name = node[0]
        env[arg_name] = argval
      }
      env[:out] = out
      Sygus::interpret(env, pred)
    }
    if res
      template
    else
      nil
    end
  end
end
