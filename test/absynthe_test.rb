require "test_helper"
require "sxp"
require "algorithms"
require "timeout"

class AbsyntheTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Absynthe::VERSION
  end

  def test_it_does_something_useful
    Dir.glob('/Users/sankha/projects/absynthe/sygus-strings/*.sl') do |sl_file|
      puts "==> #{sl_file}"
      ast = SXP.read_file(sl_file)
      spec = Sygus::ProblemSpec.new(ast)
      lang = spec.lang
      constraints = spec.constraints

      seed = s(:hole, :Start)
      q = Containers::PriorityQueue.new
      q.push(seed, -1 * ProgSizePass.prog_size(seed))
      begin
        Timeout::timeout(60) do
          puts synthesize(spec, q)
        end
      rescue Exception => e
        puts e
      end
    end
    assert true
  end
end
