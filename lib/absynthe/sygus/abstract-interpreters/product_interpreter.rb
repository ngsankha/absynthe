module Sygus
  # base class of a product interpreter
  class ProductInterpreter < AbstractInterpreter
    ::DOMAIN_INTERPRETER[ProductDomain] = self

    # it evaluates in each individual domain and then takes the product of each domain
    def self.interpret(env, node)
      _, val = env.first
      res_domains = val.domains.keys.map { |domain|
        new_env = project_env(env, domain)
        res = interpreter_from(domain).interpret(new_env, node)
        res = project_domain(res, domain) if res.is_a? ProductDomain
        res
      }.compact
      ProductDomain.val(*res_domains)
    end

    private
    def self.project_env(env, domain)
      env.map { |k, v| [k, project_domain(v, domain)] }.to_h
    end
  end
end
