require 'ast'
require 'pry'
require 'pry-byebug'

# Looks up the Python rules and fills in possible AST nodes at the hole

class ExpandHolePass < ::AST::Processor
  attr_reader :expand_map
  include VarName

  def initialize(ctx, lang)
    @ctx = ctx
    @expand_map = []
  end

  def on_hole(node)
    goal = node.children[1]
    if goal.is_a? ProductDomain
      ty = goal.domains[PyType].attrs[:ty]
    elsif goal.is_a? PyType
      ty = goal.attrs[:ty]
    else
      raise AbsyntheError, "unexpected!"
    end
    # rownums = goal.domains[PandasRows]
    interpreter = AbstractInterpreter.interpreter_from(@ctx.domain)
    expanded = []

    # Holes are filled by looking up the corresponding type definition.
    # Each case is outlined below

    # 1. consts
    # TODO: fix constants
    if RDL::Globals.types[:string] <= ty
      @ctx.consts[:str].each { |v| expanded << s(:const, v) }
    end
    if ty.is_a? RDL::Type::SingletonType
      expanded << s(:const, ty.val)
    end
    if ty.is_a? RDL::Type::PreciseStringType
      expanded << s(:const, ty.vals[0])
    end
    if RDL::Type::NominalType.new(Lambda) <= ty
      expanded << s(:const, NUnique.new)
    end
    if RDL::Type::NominalType.new(Type) <= ty
      expanded << s(:const, PyInt.new)
    end
    if RDL::Globals.types[:integer] <= ty
      @ctx.consts[:int].each { |v| expanded << s(:const, v) }
    end

    # 2. union type
    if ty.is_a? RDL::Type::UnionType
      ty.types.each { |t|
        expanded << s(:hole, nil, ProductDomain.val(PyType.val(t), PandasCols.fresh_var))
      }
    end

    # 3. vars
    @ctx.init_env.each { |name, val|
      expanded << s(:const, name.to_sym) if val <= goal
    }

    # 4. arrays
    # NOTE: all arrays are limited to max size 3 for now
    if ty.is_a?(RDL::Type::GenericType) && ty.base == RDL::Globals.types[:array]
      if ty.params[0] <= RDL::Globals.types[:integer]
        3.times { |i|
          @ctx.consts[:int].permutation(i + 1) { |arr|
            expanded << s(:array, *arr.map { |n| s(:const, n) })
          }
        }
      elsif ty.params[0] <= RDL::Globals.types[:string]
        3.times { |i|
          @ctx.consts[:str].permutation(i + 1) { |arr|
            expanded << s(:array, *arr.map { |n| s(:const, n) })
          }
        }
      elsif ty.params[0] <= RDL::Globals.types[:bool]
        expanded << s(:array, *[true, false, true].map { |n| s(:const, n) })
        expanded << s(:array, *[true, false].map { |n| s(:const, n) })
      end
    end

    # 5. hashes
    if ty.is_a? RDL::Type::FiniteHashType
      ty.elts.size.times { |i|
        keys = ty.elts.keys.combination(i + 1)
        keys.each { |ks|
          expanded << s(:hash, *ks.map { |k|
                        s(:key, k, s(:hole, nil, ProductDomain.val(PyType.val(ty.elts[k]), PandasCols.fresh_var)))
                      })
        }
      }
    end

    # 6. properties
    RDL::Globals.info.info.each { |cls, mthds|
      next if cls.to_s.include?("RDL::")
      mthds.delete(:__getobj__)
      mthds.each { |mthd, info|
        next unless [:loc_getitem, :__getitem__, :T, :values].include?(mthd)
        trecv = RDL::Type::NominalType.new(cls)
        info[:type].each { |tmeth|
          tret = tmeth.ret

          # self type not supported
          if tret.is_a? RDL::Type::VarType
            tret = ty
            # generic types with only 1 type param supported now
            trecv = RDL::Type::GenericType.new(trecv, tret)
          end

          next unless tret <= ty
          # TODO: comptypes not supported yet. See TypeOperations module in RbSyn for impl
          targs = tmeth.args
          next if targs.any? { |t| t.is_a? RDL::Type::BotType }
          tout = tmeth.ret

          expanded << s(:prop,
                        s(:hole, nil, ProductDomain.val(PyType.val(trecv), PandasCols.fresh_var)),
                        mthd,
                        *targs.map { |t|
                          s(:hole, nil, ProductDomain.val(PyType.val(t), PandasCols.fresh_var))
                        })
        }
      }
    }

    # 7. funcs
    RDL::Globals.info.info.each { |cls, mthds|
      next if cls.to_s.include?("RDL::")
      mthds.delete(:__getobj__)
      mthds.each { |mthd, info|
        next if [:loc_getitem, :__getitem__, :T, :values].include?(mthd)
        trecv = RDL::Type::NominalType.new(cls)
        info[:type].each { |tmeth|
          next unless tmeth.ret <= ty
          # puts tmeth.inspect
          # TODO: comptypes not supported yet. See TypeOperations module in RbSyn for impl

          targs = tmeth.args
          arg_terms = targs.map { |arg|
            if [RDL::Type::NominalType, RDL::Type::GenericType, RDL::Type::UnionType].any? { |t| arg.is_a? t }
              s(:hole, nil, ProductDomain.val(PyType.val(arg), PandasCols.fresh_var))
            elsif arg.is_a? RDL::Type::FiniteHashType
              s(:hole, nil, ProductDomain.val(PyType.val(arg), PandasCols.fresh_var))
            else
              raise AbsyntheError, "unexpected type #{arg}"
            end
          }
          next if targs.any? { |t| t.is_a? RDL::Type::BotType }
          tout = tmeth.ret
          expanded << s(:send,
                        s(:hole, nil, ProductDomain.val(PyType.val(trecv), PandasCols.fresh_var)),
                        mthd,
                        *arg_terms)
        }
      }
    }

    @expand_map << expanded.size
    s(:filled_hole, goal, *expanded)
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    })
  end
end
