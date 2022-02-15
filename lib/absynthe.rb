require 'parser/current'
require 'absynthe/version'
require 'absynthe/synthesizer'
require 'absynthe/language'
require 'absynthe/passes/expand_hole'
require 'absynthe/passes/extract_ast'
require 'absynthe/passes/no_hole'
require 'absynthe/passes/prog_size'
require 'absynthe/sygus/interpreter'
require 'absynthe/sygus/spec'
require 'absynthe/sygus/prefix-interpreter'

class AbsyntheError < StandardError; end

def s(kind, *children)
  Parser::AST::Node.new(kind, children)
end
