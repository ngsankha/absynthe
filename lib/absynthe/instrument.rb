class Instrumentation
  class << self
    attr_accessor :prog, :examples, :gc_time

    def reset!
      @prog = nil
      @examples = 0
      @gc_time = 0
    end

    def size
      ProgSizePass.prog_size(@prog)
    end
  end
end
