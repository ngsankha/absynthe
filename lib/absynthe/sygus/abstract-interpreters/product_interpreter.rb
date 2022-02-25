module Sygus
  class ProductInterpreter
    @@interpreters = {
      StringLength: StringLengthInterpreter,
      StringPrefix: PrefixInterpreter,
      StringSuffix: SuffixInterpreter
    }

    def self.interpret(env, node)
      _, val = env.first
      # puts val.domains
      res_domains = val.domains.keys.map { |domain|
        new_env = project_env(env, domain)
        res = @@interpreters[domain.to_s.to_sym].interpret(new_env, node)
        res = project_domain(res, domain) if res.is_a? ProductDomain
        res
      }.compact
      # puts res_domains.inspect
      ProductDomain.val(*res_domains)
    end

    private
    def self.project_env(env, domain)
      env.map { |k, v| [k, project_domain(v, domain)] }.to_h
    end

    def self.project_domain(src, target)
      src.domains[target]
    end
  end
end
