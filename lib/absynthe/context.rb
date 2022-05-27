class Context
  attr_reader :max_size, :init_env, :goal
  attr_accessor :lang, :domain
  def initialize(init_env, goal)
    @max_size = 15
    @domain = init_env.first[1].class
    @init_env = init_env
    @lang = :sygus
    @goal = goal
  end
end
