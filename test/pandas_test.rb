require "test_helper"
require "sxp"
require "fc"
require "timeout"
require "absynthe"
require "absynthe/python"
require "rdl"

class DataFrame; end

class PandasTest < Minitest::Test
  def test_pandas_type
    RDL.type :DataFrame, :xs, "(String, level: 0 or 1) -> DataFrame"

    prog = s(:send,
            s(:const, :df),
            :xs,
            s(:const, 'a'),
            s(:hash,
              s(:key, :level, s(:const, 0))))
    res = Python::PyTypeInterpreter.interpret({
      df: PyType.val(RDL::Type::NominalType.new('DataFrame'))
    }, prog)
    assert res <= PyType.val(RDL::Type::NominalType.new('DataFrame'))
  end
end
