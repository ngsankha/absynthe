DOMAIN_INTERPRETER = {}

require 'parser/current'
require 'absynthe/version'
require 'absynthe/globals'
require 'absynthe/context'
require 'absynthe/synthesizer'
require 'absynthe/language'
require 'absynthe/var_name'
require 'absynthe/domain'
require 'absynthe/passes/expand_hole'
require 'absynthe/passes/replace_dephole'
require 'absynthe/passes/extract_ast'
require 'absynthe/passes/hole_count'
require 'absynthe/passes/prog_size'
require 'absynthe/sygus/interpreter'
require 'absynthe/sygus/spec'
require 'absynthe/sygus/domains/string_length'
require 'absynthe/sygus/domains/string_prefix'
require 'absynthe/sygus/domains/string_suffix'
require 'absynthe/sygus/domains/string_length_extended'
require 'absynthe/sygus/domains/product'
require 'absynthe/sygus/abstract-interpreters/abstract_interpreter'
require 'absynthe/sygus/abstract-interpreters/prefix_interpreter'
require 'absynthe/sygus/abstract-interpreters/suffix_interpreter'
require 'absynthe/sygus/abstract-interpreters/length_interpreter'
require 'absynthe/sygus/abstract-interpreters/length_ext_interpreter'
require 'absynthe/sygus/abstract-interpreters/product_interpreter'

class AbsyntheError < StandardError; end

def s(kind, *children)
  Parser::AST::Node.new(kind, children)
end
