class TermGenerator
  def initialize(lang, interp, env)
    @lang = lang
    # cache :: {rulename: {nesting: {absval: [terms]}}}
    @cache = {}
    @interp = interp
    @env = env
  end

  def get_terms(rulename, nesting, absval)

  end

  private
  def fill_init_terminals
    @lang.rules.each { |rulename, prods|
      prods.each { |elem|
        if elem.is_a? Terminal
          term = s(:const, elem.name)
          add_term(rulename, 0 term)
        end
      }
    }
  end

  def build_terms(nesting)
    @lang.rules.each { |rulename, prods|
      prods.each { |elem|
        if elem.is_a? NonTerminal
          
          term = s(:const, elem.name)
          add_term(rulename, 0 term)
        end
      }
    }
  end

  def add_term(rulename, nesting, term)
    absval = @interp.interp(env, term)
    @cache[rulename] = {} unless @cache.key? rulename
    @cache[rulename][nesting] = {} unless @cache[rulename].key? nesting
    @cache[rulename][nesting][absval] = [] unless @cache[rulename][nesting].key? absval
    @cache[rulename][nesting][absval] << term
  end
end
