module Sygus
  def self.interpret(env, node)
    case node.type
    when :const
      konst = node.children[0]
      case konst
      when String, Integer, true, false
        konst
      when Symbol
        env[konst]
      else
        raise AbsyntheError, "unexpected constant type"
      end
    when :send
      case node.children[0]
      when :"str.++"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0 + arg1
      when :"str.replace"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg2 = interpret(env, node.children[3])
        arg0.gsub(arg1, arg2)
      when :"str.at"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0[arg1]
      when :"int.to.str"
        arg0 = interpret(env, node.children[1])
        # compliance with sygus
        if arg0 >= 0
          arg0.to_s
        else
          ""
        end
      when :"str.substr"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg2 = interpret(env, node.children[3])
        # compliance with sygus
        if arg2 < 0 || arg1 < 0 || arg1 > arg0.size
          ""
        else
          arg0[arg1...arg2]
        end
      when :+
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0 + arg1
      when :-
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0 - arg1
      when :"str.len"
        arg0 = interpret(env, node.children[1])
        arg0.size
      when :"str.to.int"
        arg0 = interpret(env, node.children[1])
        # compliance with sygus
        if arg0.chars.all? { |c| ('0'..'9').include? c }
          arg0.to_i
        else
          -1
        end
      when :"str.indexof"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg2 = interpret(env, node.children[3])
        arg0.index(arg1, arg2)
      when :"str.prefixof"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0.start_with?(arg1)
      when :"str.suffixof"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0.end_with?(arg1)
      when :"str.contains"
        arg0 = interpret(env, node.children[1])
        arg1 = interpret(env, node.children[2])
        arg0.include?(arg1)
      else
        raise AbsyntheError, "unexpected AST node"
      end
    end
  end

  def self.unparse(node)
    case node.type
    when :const
      konst = node.children[0]
      case konst
      when Integer, true, false, Symbol
        konst.to_s
      when String
        konst.inspect
      else
        raise AbsyntheError, "unexpected constant type"
      end
    when :send
      args = node.children[1..].map { |n| unparse(n) }.join(" ")
      "(#{node.children[0]} #{args})"
    when :hole
      # "(□: #{node.children[1]})"
      "□"
    when :dephole
      # "(□: #{node.children[1]})"
      "◐"
    else
      raise AbsyntheError, "unexpected AST node #{node.type}"
    end
  end
end
