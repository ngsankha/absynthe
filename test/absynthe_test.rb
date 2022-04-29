require "test_helper"
require "sxp"
require "fc"
require "timeout"

class AbsyntheTest < Minitest::Test
  def test_that_absynthe_has_a_version_number
    refute_nil ::Absynthe::VERSION
  end

  def test_eval_dephole
    prog = s(:send, :"str.substr",
             s(:hole, :ntString, StringLenExt.fresh_var),
             s(:hole,    :ntInt, StringLenExt.fresh_var),
             s(:dephole, :ntInt, StringLenExt.fresh_var))
    res = Sygus::StringLenExtInterpreter.interpret({}, prog)
    assert res <= StringLenExt.val(3)
  end

  def test_domains_solvable
    refute StringLength.top.solvable?
    refute StringPrefix.top.solvable?
    refute StringSuffix.top.solvable?

    assert StringLenExt.top.solvable?

    refute ProductDomain.val(StringLength.top, StringPrefix.top).solvable?
    assert ProductDomain.val(StringLenExt.top, StringPrefix.top).solvable?
  end

  def test_str_len_ext_values
    dom1 = StringLenExt.from("foo")
    dom2 = StringLenExt.from("bar")
    dom3 = StringLenExt.from("foobar")
    dom4 = StringLenExt.from(3)
    dom5 = StringLenExt.from(true)
    assert_equal dom1, dom2
    assert_equal dom1, dom4
    assert_equal dom1.attrs[:val], 3
    assert_equal dom2.attrs[:val], 3
    assert_equal dom3.attrs[:val], 6
    assert_equal dom4.attrs[:val], 3
    assert_equal dom5.attrs[:val], true
    assert_raises AbsyntheError do
      StringLenExt.from(Hash.new)
    end
  end

  def test_string_prefix_domain
    top = StringPrefix.top
    bot = StringPrefix.bot
    dom1 = StringPrefix.val("Dr", true)
    dom2 = StringPrefix.val("Dr. ", true)
    var = StringPrefix.var('x')
    Globals.root_vars = [var]

    assert bot <= top
    assert dom1 <= top
    assert dom2 <= top
    assert bot <= dom1
    assert bot <= dom2
    assert dom2 <= dom1

    assert var <= top
    assert var <= bot
    refute var <= dom1
    refute var <= dom2

    refute top <= var
    assert bot <= var
    refute dom1 <= var
    refute dom2 <= var

    assert dom2 != dom1
    assert top == top
    assert bot == bot
    assert dom1 == dom1
  end

  def test_string_suffix_domain
    var1 = StringSuffix.var('var1')
    var2 = StringSuffix.var('var2')
    var3 = StringSuffix.var('var1', 5)
    var4 = StringSuffix.var('var1', 3)
    dom1 = StringSuffix.val("bar", true)
    dom2 = StringSuffix.val("foobar", true)
    Globals.root_vars = [var1, var2, var3, var4]

    refute var1 <= var2
    refute var2 <= var1
    refute var3 <= var2
    refute var2 <= var3
    refute var1 <= dom1
    refute dom1 <= var1
    refute var2 <= dom1
    refute dom1 <= var2
    refute var3 <= dom1
    refute dom1 <= var3

    assert var1 <= var4
    refute var4 <= var1
    assert var3 <= var4
    refute var4 <= var3
    assert dom2 <= dom1
    refute dom1 <= dom2
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

  def test_phone_3
    prog = s(:send, :"str.++",
              s(:send, :"str.++",
                s(:send, :"str.++",
                  s(:const, "("),
                  s(:send, :"str.++",
                    s(:send, :"str.substr",
                      s(:const, :name),
                      s(:const, 0),
                      s(:const, 3)),
                    s(:const, ")"))),
                s(:const, " ")),
              s(:send, :"str.substr",
                s(:const, :name),
                s(:const, 4),
                s(:send, :"str.len",
                  s(:const, :name))))
    # (str.++ (str.++ (str.++ "(" (str.++ (str.substr name 0 3) ")")) " ") (str.substr name 4 (str.len name)))
    res = Sygus::interpret({:name => "938-242-504"}, prog)
    assert_equal res, "(938) 242-504"
  end

  def test_phone_4
    prog = s(:send, :"str.replace",
            s(:const, :name),
            s(:const, "-"),
            s(:const, "."))
    # (str.replace name "-" ".")
    res = Sygus::interpret({:name => "938-242-504"}, prog)
    assert_equal res, "938.242.504"
  end

  def test_phone_5
    prog = s(:send, :"str.substr",
            s(:const, :name),
            s(:const, 1),
            s(:send, :"str.indexof",
              s(:const, :name),
              s(:const, " "),
              s(:const, 0)))
    # (str.substr name 1 (str.indexof name " " 0))
    res = Sygus::interpret({:name => "+106 769-858-438"}, prog)
    assert_equal res, "106"
  end

  def test_phone_6
    prog = s(:send, :"str.substr",
            s(:const, :name),
            s(:send, :+,
                s(:const, 1),
                s(:send, :"str.indexof",
                  s(:const, :name),
                  s(:const, " "),
                  s(:const, 0))),
            s(:send, :+,
                s(:const, 4),
                s(:send, :"str.indexof",
                  s(:const, :name),
                  s(:const, " "),
                  s(:const, 0))))
    # (str.substr name (+ 1 (str.indexof name " " 0)) (+ 4 (str.indexof name " " 0)))
    res = Sygus::interpret({:name => "+106 769-858-438"}, prog)
    assert_equal res, "769"
    # res = Sygus::StringLenExtInterpreter.interpret({:name => StringLenExt.top}, prog)
    # assert_equal res, StringLenExt.val(3)
  end

  def test_phone_7
    prog = s(:send, :"str.substr",
            s(:const, :name),
            s(:send, :+,
              s(:send, :"str.indexof",
                s(:const, :name),
                s(:const, "-"),
                s(:const, 0)),
              s(:const, 1)),
            s(:send, :+,
              s(:send, :"str.indexof",
                s(:const, :name),
                s(:const, "-"),
                s(:const, 0)),
              s(:const, 4)))
    # (str.substr name (+ (str.indexof name "-" 0) 1) (+ (str.indexof name "-" 0) 4))
    res = Sygus::interpret({:name => "+106 769-858-438"}, prog)
    assert_equal res, "858"
  end

  def test_phone_8
    prog = s(:send, :"str.substr",
            s(:const, :name),
            s(:send, :-,
              s(:send, :"str.len",
                s(:const, :name)),
              s(:const, 3)),
            s(:send, :"str.len",
              s(:const, :name)))
    # (str.substr name (- (str.len name) 3) (str.len name))
    res = Sygus::interpret({:name => "+106 769-858-438"}, prog)
    assert_equal res, "438"
  end

  def test_phone_9
    prog = s(:send, :"str.substr",
            s(:send, :"str.replace",
              s(:send, :"str.replace",
                s(:const, :name),
                s(:const, " "),
                s(:const, ".")),
              s(:const, "-"),
              s(:const, ".")),
            s(:const, 1),
            s(:send, :"str.len",
              s(:const, :name)))
    # (str.substr (str.replace (str.replace name " " ".") "-" ".") 1 (str.len name))
    res = Sygus::interpret({:name => "+106 769-858-438"}, prog)
    assert_equal res, "106.769.858.438"
  end

  def test_phone_10
    frag1 = s(:send, :"str.++",
              s(:send, :"str.++",
                s(:const, "("),
                s(:send, :"str.substr",
                  s(:const, :name),
                  s(:send, :+,
                    s(:send, :"str.indexof",
                      s(:const, :name),
                      s(:const, " "),
                      s(:const, 0)),
                    s(:const, 1)),
                  s(:send, :+,
                    s(:send, :"str.indexof",
                      s(:const, :name),
                      s(:const, " "),
                      s(:const, 0)),
                    s(:const, 4)))),
              s(:const, ")"))

    frag2 = s(:send, :"str.substr",
              s(:const, :name),
              s(:const, 0),
              s(:send, :"str.indexof",
                s(:const, :name),
                s(:const, " "),
                s(:const, 0)))

    frag3 = s(:send, :"str.substr",
              s(:const, :name),
              s(:send, :-,
                s(:send, :"str.len",
                  s(:const, :name)),
                s(:send, :+,
                  s(:const, 3),
                  s(:const, 4))),
              s(:send, :"str.len",
                s(:const, :name)))

    prog = s(:send, :"str.++",
              frag2,
              s(:send, :"str.++",
                s(:const, " "),
                s(:send, :"str.++",
                  frag1,
                  s(:send, :"str.++",
                    s(:const, " "),
                    frag3))))

    # (str.++ (str.substr name 0 (str.indexof name " " 0)) (str.++ " " (str.++ (str.++ (str.++ "(" (str.substr name (+ (str.indexof name " " 0) 1) (+ (str.indexof name " " 0) 4))) ")") (str.++ " " (str.substr name (- (str.len name) (+ 3 4)) (str.len name))))))
    res = Sygus::interpret({:name => "+106 769-858-438"}, prog)
    assert_equal res, "+106 (769) 858-438"
  end
end
