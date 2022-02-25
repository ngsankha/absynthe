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
          # absval = Sygus::ProductInterpreter.interpret(ctx.init_env, prog)
          src = Sygus::unparse(prog)
          if true # absval <= ctx.goal
            # puts "#{src} :: #{absval}"
            size = ProgSizePass.prog_size(prog)
            q.push(prog, size) if size <= ctx.max_size
          end
        else
          # puts Sygus::unparse(prog)
          if spec.test_prog(prog)
            return prog
          end
        end
      }
  end
  raise AbsyntheError, "No candidates found!"
end

def score(prog)
  num_holes = HoleCountPass.holes(prog)
  size = ProgSizePass.prog_size(prog)
  # (num_holes * 100) + size
  size
end
