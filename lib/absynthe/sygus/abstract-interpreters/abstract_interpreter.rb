class AbstractInterpreter
  def self.interpreter_from(domain)
    ::DOMAIN_INTERPRETER[domain]
  end

  def self.eval_hole(node)
    return node.children[1] if node.children[1].class == domain
    project_domain(node.children[1], domain)
  end

  def self.domain
    raise AbsyntheError, "unimplemented!"
  end

  private
  def self.project_domain(src, target)
    raise AbsyntheError, "no target domain specified" if target.nil?
    src.domains[target]
  end
end
