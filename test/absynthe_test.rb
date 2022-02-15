require "test_helper"
require "sxp"
require "algorithms"
require "timeout"

class AbsyntheTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Absynthe::VERSION
  end

  def test_string_prefix_domain
    top = Sygus::StringPrefix::top
    bot = Sygus::StringPrefix::bot
    dom1 = Sygus::StringPrefix.new("Dr")
    dom2 = Sygus::StringPrefix.new("Dr. ")

    assert bot <= top
    assert dom1 <= top
    assert dom2 <= top
    assert bot <= dom1
    assert bot <= dom2
    assert dom2 <= dom1

    assert dom2 != dom1
    assert top == top
    assert bot == bot
    assert dom1 == dom1
  end

  def test_string_prefix_interpreter
    prog = s(:send, :"str.++", s(:const, "Dr."),
            s(:send, :"str.++", s(:const, " "),
              s(:send, :"str.substr",
                s(:const, :name),
                s(:const, 0),
                s(:send, :"str.indexof",
                  s(:const, :name),
                  s(:const, " "),
                  s(:const, 0)))))

    res = Sygus::PrefixInterpreter.interpret({:name => "Sankha Guria"}, prog)
    assert_equal "#{res}", "Dr."
    res = Sygus::interpret({:name => "Sankha Guria"}, prog)
    assert_equal res, "Dr. Sankha"
  end

  def test_it_does_something_useful
    skip
    Dir.glob('./sygus-strings/{bikes,phone,phone-2,firstname}.sl') do |sl_file|
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
