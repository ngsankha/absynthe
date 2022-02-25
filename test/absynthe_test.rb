require "test_helper"
require "sxp"
require "fc"
require "timeout"

class AbsyntheTest < Minitest::Test
  def test_that_absynthe_has_a_version_number
    refute_nil ::Absynthe::VERSION
  end

  def test_string_prefix_domain
    top = StringPrefix.top
    bot = StringPrefix.bot
    dom1 = StringPrefix.val("Dr", true)
    dom2 = StringPrefix.val("Dr. ", true)
    var = StringPrefix.var(:x)

    assert bot <= top
    assert dom1 <= top
    assert dom2 <= top
    assert bot <= dom1
    assert bot <= dom2
    assert dom2 <= dom1

    assert var <= top
    assert var <= bot
    assert var <= dom1
    assert var <= dom2

    assert top <= var
    assert bot <= var
    assert dom1 <= var
    assert dom2 <= var

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
    assert_equal "#{res}", "\"Dr. \""
    res = Sygus::interpret({:name => "Sankha Guria"}, prog)
    assert_equal res, "Dr. Sankha"
  end

  def test_sygus_conc_interpreter
    prog = s(:send, :"str.++", s(:const, :lastname),
            s(:send, :"str.++", s(:const, " "),
              s(:const, :firstname)))

    res = Sygus::interpret({:firstname => "Launa", :lastname => "Withers"}, prog)
    assert_equal res, "Withers Launa"
  end

  def test_sygus_test_from_spec
    prog = s(:send, :"str.++", s(:const, :lastname),
            s(:send, :"str.++", s(:const, " "),
              s(:const, :firstname)))

    ast = SXP.read_file('./sygus-strings/reverse-name.sl')
    spec = Sygus::ProblemSpec.new(ast)
    assert spec.test_prog(prog)
  end

  def test_interp_partial_program
    prog = s(:send, :"str.++", s(:const, "Dr."),
            s(:send, :"str.++", s(:const, " "),
              s(:hole, :ntString, StringPrefix.top)))

    res = Sygus::PrefixInterpreter.interpret({:name => "Sankha Guria"}, prog)
    assert res <= StringPrefix.val("Dr. ", true)
  end
end
