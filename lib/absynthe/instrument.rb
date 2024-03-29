require 'json'

# Used to track statistics during synthesis. This is used to generate the
# tables in the artifact and the paper

class Instrumentation
  class << self
    attr_accessor :size, :examples, :gc_time, :tested_progs, :height, :eliminated, :domain

    def reset!
      @size = nil
      @examples = 0
      @gc_time = 0
      @tested_progs = 0
      @height = 0
      @eliminated = 0
      @domain = ""
    end

    def from_json(obj)
      @size = obj["size"]
      @examples = obj["examples"]
      @gc_time = obj["gc_time"]
      @tested_progs = obj["tested_progs"]
      @height = obj["height"]
      @eliminated = obj["eliminated"]
      @domain = obj["domain"]
    end

    def to_json
      {:size => @size,
       :examples => @examples,
       :gc_time => @gc_time,
       :tested_progs => @tested_progs,
       :height => @height,
       :eliminated => @eliminated,
       :domain => @domain
     }.to_json
    end
  end
end
