DOMAIN_INTERPRETER = {}

require 'parser/current'
require 'absynthe/version'
require 'absynthe/globals'
require 'absynthe/instrument'
require 'absynthe/context'
require 'absynthe/cache'
require 'absynthe/synthesizer'
require 'absynthe/language'
require 'absynthe/template_infer'
require 'absynthe/var_name'
require 'absynthe/domain'
require 'absynthe/passes/expand_hole'
require 'absynthe/passes/replace_dephole'
require 'absynthe/passes/extract_ast'
require 'absynthe/passes/hole_count'

class AbsyntheError < StandardError; end

def s(kind, *children)
  Parser::AST::Node.new(kind, children)
end
