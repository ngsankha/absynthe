require "test_helper"
require "sxp"
require "fc"
require "timeout"
require "absynthe"
require "absynthe/python"
require "rdl"

class DataFrame; end
class NUnique; end
class Type; end
class PyInt < Type; end
RDL.type_params :Array, [:t], :all?

class PandasTest < Minitest::Test
  def test_pandas_1
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

  def test_pandas_2
    RDL.type :DataFrame, :sort_values, "(by: Array<String>, ascending: Array<true or false>) -> DataFrame"

    prog = s(:send,
            s(:const, :df),
            :sort_values,
            s(:hash,
              s(:key, :by,
                s(:array,
                  s(:const, "ID"),
                  s(:const, "first"),
                  s(:const, "admit"))),
              s(:key, :ascending,
                s(:array,
                s(:const, true),
                s(:const, false),
                s(:const, true)))))
    res = Python::PyTypeInterpreter.interpret({
      df: PyType.val(RDL::Type::NominalType.new('DataFrame'))
    }, prog)
    assert res <= PyType.val(RDL::Type::NominalType.new('DataFrame'))
  end

  def test_pandas_3
    RDL.type :DataFrame, :loc_getitem, "(Array<Integer>) -> DataFrame"
    RDL.type :DataFrame, :loc_getitem, "(Lambda) -> DataFrame"

    prog = s(:prop,
            s(:const, :df),
            :loc_getitem,
            s(:array,
              s(:const, 0),
              s(:const, 2),
              s(:const, 4)))

    res = Python::PyTypeInterpreter.interpret({
      df: PyType.val(RDL::Type::NominalType.new('DataFrame'))
    }, prog)
    assert res <= PyType.val(RDL::Type::NominalType.new('DataFrame'))
  end

  def test_promote_pytype_1
    ty = RDL::Type::GenericType.new(
      RDL::Globals.types[:array],
      RDL::Type::UnionType.new(
        RDL::Type::SingletonType.new(1),
        RDL::Type::SingletonType.new(2)))
    pytype = PyType.val(ty).promote

    assert_equal pytype.attrs[:ty],
                 RDL::Type::GenericType.new(
                  RDL::Globals.types[:array],
                  RDL::Globals.types[:integer])
  end

  def test_promote_pytype_2
    ty = RDL::Type::GenericType.new(
      RDL::Globals.types[:array],
      RDL::Type::UnionType.new(
        RDL::Type::SingletonType.new("foo"),
        RDL::Type::SingletonType.new("bar")))
    pytype = PyType.val(ty).promote

    assert_equal pytype.attrs[:ty], ty
  end

  def test_promote_pytype_3
    ty = RDL::Type::GenericType.new(
      RDL::Globals.types[:array],
        RDL::Type::SingletonType.new(1))
    pytype = PyType.val(ty).promote

    assert_equal pytype.attrs[:ty],
                 RDL::Type::GenericType.new(
                  RDL::Globals.types[:array],
                  RDL::Globals.types[:integer])
  end

  def test_generic_pytype
    RDL.type :Array, :__getitem__, "(Integer) -> t"

    prog = s(:prop,
            s(:const, :arg1),
            :__getitem__,
            s(:const, 0))

    res = Python::PyTypeInterpreter.interpret({
      arg1: PyType.val(RDL::Globals.parser.scan_str("() -> Array<Array<Integer>>").ret)
    }, prog)
    assert res <= PyType.val(RDL::Globals.parser.scan_str("() -> Array<Integer>").ret)
  end
end
