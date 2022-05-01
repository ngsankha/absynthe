class Globals
  @root_vars = []
  # prev_model is over-written after each <= operation in solver backed domains
  # TODO: mitigate this so that in some bright future this can be parallelized
  @prev_model = nil

  class << self
    attr_accessor :root_vars
    attr_accessor :prev_model
  end

  def self.root_vars_include? var
    return false unless var.var?
    !self.root_vars.find { |v| v.attrs[:name] == var.attrs[:name] }.nil?
  end
end
