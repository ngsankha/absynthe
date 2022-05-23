require "test_helper"
require "sxp"
require "fc"
require "timeout"
require "pandas"

class SygusTest < Minitest::Test
  def test_pandas
    prog = s(:send, :"str.substr",
             s(:hole, :ntString, StringLenExt.fresh_var),
             s(:hole,    :ntInt, StringLenExt.fresh_var),
             s(:dephole, :ntInt, StringLenExt.fresh_var))
    res = Sygus::StringLenExtInterpreter.interpret({}, prog)
    assert res <= StringLenExt.val(3)
  end
end
