# Base class for defining abstract interpreters

class AbstractInterpreter
  # returns the interpreter for a given domain
  def self.interpreter_from(domain)
    ::DOMAIN_INTERPRETER[domain]
  end

  # evaluates the hole, and returns the projection of the abstract value in the
  # domain for which the current interpter is defined
  def self.eval_hole(node)
    return node.children[1] if node.children[1].class == domain
    project_domain(node.children[1], domain)
  end

  def self.eval_dephole(node)
    node.children[1]
  end

  def self.domain
    raise AbsyntheError, "unimplemented!"
  end

  private
  def self.project_domain(src, target)
    raise AbsyntheError, "no target domain specified" if target.nil?
    return src.domains[target] if src.domains.key? target
    target.top
  end
end
