class Context
  attr_reader :max_size, :domain, :init_env, :goal
  def initialize(init_env, goal)
    @max_size = 5
    @domain = init_env.first[1].class
    @init_env = init_env
    @goal = goal
  end
end
