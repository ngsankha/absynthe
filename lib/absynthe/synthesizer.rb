# The following algorithm is described with reference of Absynthe paper: Algorithm 1

def synthesize(ctx, spec, q)
  if ctx.lang == :sygus
    lang = spec.lang
  else
    lang = nil
  end

  # line 5
  until q.empty? do
    # line 6
    current = q.top
    q.pop

    # next few lines are for line 7
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
        # puts "==>"
        # puts prog

        # next few lines are for line 8
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
          score = ctx.score.call(prog)
          size = ProgSizePass.prog_size(prog)
          # line 15
          q.push(prog, score) if size <= ctx.max_size
        else
          Instrumentation.eliminated += 1
        end
      else
        # src = Sygus::unparse(prog)
        # puts src
        # line 12
        if spec.test_prog(prog)
          return prog
        else
          Instrumentation.tested_progs += 1
        end
      end
    }
  end
  raise AbsyntheError, "No candidates found!"
end
