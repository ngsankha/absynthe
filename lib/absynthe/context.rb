class Context
  attr_reader :max_size, :init_env, :goal, :consts
  attr_accessor :lang, :domain, :cache, :score
  def initialize(init_env, goal)
    @max_size = 25
    @domain = init_env.first[1].class
    @init_env = init_env
    @lang = :sygus
    @goal = goal
    @cache = {}
    @score = Proc.new { |prog| ProgSizePass.prog_size(prog) }
    @consts = {}
  end
end
