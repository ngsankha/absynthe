class Cache
  # generates a cache of small terms, that enables these function applications
  # to be substituted just like constants

  def self.populate_sygus(ctx, lang)
    cache = {}
    templates = {}

    # generate function applications
    lang.rules.each { |rulename, rule|
      next unless rulename.to_s.start_with? "nt"
      templates[rulename] = []
      rule.each { |r|
        next if r.is_a? Terminal
        args = r.args.map { |n| s(:hole, n, ctx.domain.top) }
        templates[rulename] << s(:send, r.name, *args)
      }
    }

    # fill holes function application args
    templates.each { |rulename, t|
      cache[rulename] = []
      t.each { |p|
        pass = ExpandHolePass.new(ctx, lang)
        expanded = pass.process(p)
        expand_map = pass.expand_map.map { |i| i.times.to_a }
        candidates = expand_map[0].product(*expand_map[1..])
        candidates.each { |selection|
          extract_pass = ExtractASTPass.new(selection)
          prog = extract_pass.process(expanded)
          hc_pass = HoleCountPass.new
          hc_pass.process(prog)
          total_holes = hc_pass.num_holes + hc_pass.num_depholes
          if (total_holes == 0 && hc_pass.num_var > 0)
            unparsed = Sygus::unparse(prog)
            cache[rulename] << prog if (rulename == :ntInt &&
                                        unparsed.start_with?("(str.indexof name ") &&
                                        unparsed.end_with?(" 0)"))
          end
        }
      }
    }
    cache
  end
end
