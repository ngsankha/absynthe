def synthesize(spec, q)
  lang = spec.lang
  constraints = spec.constraints

  until q.empty? do
    current = q.pop
    pass = ExpandHolePass.new(lang)
    expanded = pass.process(current)
    expand_map = pass.expand_map.map { |i| i.times.to_a }
    expand_map[0].product(*expand_map[1..expand_map.size])
      .map { |selection|
        extract_pass = ExtractASTPass.new(selection, lang)
        prog = extract_pass.process(expanded)
        if NoHolePass.has_hole?(prog)
          q.push(prog, -1 * ProgSizePass.prog_size(prog))
        elsif spec.test_prog(prog)
          return prog
        end
      }
  end
end
