require 'ast'
require 'pry'
require 'pry-byebug'

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

    # consts
    # TODO: fix constants
    if RDL::Globals.types[:string] <= ty
      # ['a', 'series', 'value', 'step',
      #  'X', 'Y', 'Z', 'name', 'ffill',
      #  'Group', 'Var1', 'Var2', 'yes',
      #  'STK_ID', 'bfill', 
       ['Var', 'Mean'].each { |v| expanded << s(:const, v) }
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
      [0, 1, 10].each { |v| expanded << s(:const, v) }
    end

    # union type
    if ty.is_a? RDL::Type::UnionType
      ty.types.each { |t|
        expanded << s(:hole, nil, PyType.val(t))
      }
    end

    # vars
    @ctx.init_env.each { |name, val|
      expanded << s(:const, name.to_sym) if val <= goal
    }

    # arrays
    # if ty.is_a?(RDL::Type::GenericType) && ty.base == RDL::Globals.types[:array] && ty.params[0] == RDL::Globals.types[:integer]
    #   if rownums.var?
    #     expanded << s(:array,
    #       *rownums.glb.attrs[:rownums]
    #         .to_a.map { |n| s(:const, n) })
    #   end
    # end
    if ty.is_a?(RDL::Type::GenericType) && ty.base == RDL::Globals.types[:array]
      if ty.params[0] <= RDL::Globals.types[:integer]
        expanded << s(:array, *[0, 2, 4].map { |n| s(:const, n) })
      elsif ty.params[0] <= RDL::Globals.types[:string]
        # expanded << s(:array, *['ID', 'first', 'admit'].map { |n| s(:const, n) })
        # expanded << s(:array, *['type', 'date'].map { |n| s(:const, n) })
        # expanded << s(:array, *['SEGM1', 'Distribuzione Ponderata'].map { |n| s(:const, n) })
        # expanded << s(:array, *['id'].map { |n| s(:const, n) })
        # expanded << s(:array, *['ip', 'useragent'].map { |n| s(:const, n) })
        # expanded << s(:array, *['id1', 'id2'].map { |n| s(:const, n) })
        # expanded << s(:array, *['col1', 'col2'].map { |n| s(:const, n) })
        # expanded << s(:array, *['col3'].map { |n| s(:const, n) })
        # expanded << s(:array, *['doc_created_month', 'doc_created_year', 'speciality'].map { |n| s(:const, n) })
        # expanded << s(:array, *['Passes', 'Tackles'].map { |n| s(:const, n) })
        expanded << s(:array, *['a', 'b'].map { |n| s(:const, n) })
      elsif ty.params[0] <= RDL::Globals.types[:bool]
        expanded << s(:array, *[true, false, true].map { |n| s(:const, n) })
        expanded << s(:array, *[true, false].map { |n| s(:const, n) })
      # else
      #   raise AbsyntheError, "unhandled type"
      end
    end

    # hashes
    if ty.is_a? RDL::Type::FiniteHashType
      ty.elts.size.times { |i|
        keys = ty.elts.keys.combination(i + 1)
        keys.each { |ks|
          expanded << s(:hash, *ks.map { |k|
                        s(:key, k, s(:hole, nil, PyType.val(ty.elts[k])))
                      })
        }
      }
    end

    # props
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
          # puts "var type detected" if tout.is_a? RDL::Type::VarType
          # expanded << s(:prop,
          #               s(:hole, nil, ProductDomain.val(PyType.val(trecv), PandasRows.fresh_var)),
          #               mthd,
          #               *targs.map { |t|
          #                 s(:hole, nil, ProductDomain.val(PyType.val(t), PandasRows.fresh_var))
          #               })

          expanded << s(:prop,
                        s(:hole, nil, PyType.val(trecv)),
                        mthd,
                        *targs.map { |t|
                          s(:hole, nil, PyType.val(t))
                        })
        }
      }
    }

    # funcs
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
              # s(:hole, nil, ProductDomain.val(PyType.val(arg), PandasRows.fresh_var))
              s(:hole, nil, PyType.val(arg))
            elsif arg.is_a? RDL::Type::FiniteHashType
              # s(:hash, *arg.elts.map { |k, v|
              #   s(:key, k, s(:hole, nil, ProductDomain.val(PyType.val(v), PandasRows.fresh_var)))
              #   })
              s(:hole, nil, PyType.val(arg))
            else
              raise AbsyntheError, "unexpected type #{arg}"
            end
          }
          next if targs.any? { |t| t.is_a? RDL::Type::BotType }
          tout = tmeth.ret
          # expanded << s(:send,
          #               s(:hole, nil, ProductDomain.val(PyType.val(trecv), PandasRows.fresh_var)),
          #               mthd,
          #               *arg_terms)
          expanded << s(:send,
                        s(:hole, nil, PyType.val(trecv)),
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
