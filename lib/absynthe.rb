require 'parser/current'
require 'absynthe/version'
require 'absynthe/context'
require 'absynthe/synthesizer'
require 'absynthe/language'
require 'absynthe/passes/expand_hole'
require 'absynthe/passes/extract_ast'
require 'absynthe/passes/hole_count'
require 'absynthe/passes/prog_size'
require 'absynthe/sygus/interpreter'
require 'absynthe/sygus/spec'
require 'absynthe/sygus/prefix-interpreter'
require 'absynthe/sygus/suffix-interpreter'
require 'absynthe/sygus/length-interpreter'

class AbsyntheError < StandardError; end

def s(kind, *children)
  Parser::AST::Node.new(kind, children)
end
