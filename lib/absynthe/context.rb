class Context
  attr_reader :max_size, :domain
  def initialize
    @max_size = 10
    @domain = Sygus::StringPrefix
  end
end
