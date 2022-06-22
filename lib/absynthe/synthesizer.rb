def synthesize(ctx, spec, q)
  if ctx.lang == :sygus
    lang = spec.lang
  else
    lang = nil
  end

  until q.empty? do
    current = q.top
    q.pop
    pass = ExpandHolePass.new(ctx, lang)
    # puts Sygus::unparse(current)
    # puts current
    expanded = pass.process(current)
    expand_map = pass.expand_map.map { |i| i.times.to_a }
    if expand_map.empty?
      candidates = [current]
    else
      candidates = expand_map[0].product(*expand_map[1..])
    end
    candidates.each { |selection|
      extract_pass = ExtractASTPass.new(selection)
      prog = extract_pass.process(expanded)
      hc_pass = HoleCountPass.new
      hc_pass.process(prog)
      total_holes = hc_pass.num_holes + hc_pass.num_depholes
      if total_holes > 0
        # if not satisfied by goal abstract value, program is rejected
        interpreter = AbstractInterpreter.interpreter_from(ctx.domain)
        absval = interpreter.interpret(ctx.init_env, prog)
        # src = Sygus::unparse(prog)
        # puts "#{src} :: #{absval}"

        # solve dependent holes at <=, model gives value to remaining hole
        if absval <= ctx.goal
          if hc_pass.num_holes == 0
            dephole_replacer = ReplaceDepholePass.new(ctx, hc_pass.num_depholes)
            if hc_pass.num_depholes > 0
              prog = dephole_replacer.process(prog)
            else
              raise AbsyntheError, "invariant of 1 dephole broken"
            end
          end
          size = ProgSizePass.prog_size(prog)
          q.push(prog, size) if size <= ctx.max_size
        end
      else
        # src = Sygus::unparse(prog)
        # puts src
        return prog if spec.test_prog(prog)
      end
    }
  end
  raise AbsyntheError, "No candidates found!"
end

def score(prog)
  # hc_pass = HoleCountPass.new
  # hc_pass.process(prog)
  # hc_pass.num_holes + hc_pass.num_depholes
  ProgSizePass.prog_size(prog)
  # (num_holes * 100) + size
end
