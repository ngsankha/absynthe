class Globals
  @root_vars = []

  class << self
    attr_accessor :root_vars
  end

  def self.root_vars_include? var
    return false unless var.var?
    !self.root_vars.find { |v| v.attrs[:name] == var.attrs[:name] }.nil?
  end
end
