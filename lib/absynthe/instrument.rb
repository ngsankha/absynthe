require 'json'

class Instrumentation
  class << self
    attr_accessor :size, :examples, :gc_time, :tested_progs, :height, :eliminated

    def reset!
      @size = nil
      @examples = 0
      @gc_time = 0
      @tested_progs = 0
      @height = 0
      @eliminated = 0
    end

    def from_json(obj)
      @size = obj["size"]
      @examples = obj["examples"]
      @gc_time = obj["gc_time"]
      @tested_progs = obj["tested_progs"]
      @height = obj["height"]
      @eliminated = obj["eliminated"]
    end

    def to_json
      {:size => @size,
       :examples => @examples,
       :gc_time => @gc_time,
       :tested_progs => @tested_progs,
       :height => @height,
       :eliminated => @eliminated
     }.to_json
    end
  end
end
