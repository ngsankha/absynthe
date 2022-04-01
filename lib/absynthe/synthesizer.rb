def synthesize(ctx, spec, q)
  lang = spec.lang
  constraints = spec.constraints

  until q.empty? do
    current = q.top
    q.pop
    pass = ExpandHolePass.new(ctx, lang)
    expanded = pass.process(current)
    expand_map = pass.expand_map.map { |i| i.times.to_a }
    expand_map[0].product(*expand_map[1..])
      .each { |selection|
        extract_pass = ExtractASTPass.new(selection)
        prog = extract_pass.process(expanded)
        num_holes = HoleCountPass.holes(prog)
        if num_holes > 0
          # if not satisfied by goal abstract value, program is rejected
          interpreter = AbstractInterpreter.interpreter_from(ctx.domain)
          absval = interpreter.interpret(ctx.init_env, prog)
          if absval <= ctx.goal
            # src = Sygus::unparse(prog)
            # puts "#{src} :: #{absval}"
            size = ProgSizePass.prog_size(prog)
            q.push(prog, size) if size <= ctx.max_size
          end
        else
          # src = Sygus::unparse(prog)
          # interpreter = AbstractInterpreter.interpreter_from(ctx.domain)
          # absval = interpreter.interpret(ctx.init_env, prog)
          # puts "#{src} :: #{absval}"
          if spec.test_prog(prog)
            return prog
          end
        end
      }
  end
  raise AbsyntheError, "No candidates found!"
end

def score(prog)
  # num_holes = HoleCountPass.holes(prog)
  ProgSizePass.prog_size(prog)
  # (num_holes * 100) + size
end
