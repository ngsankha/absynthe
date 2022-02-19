$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "absynthe"

require "minitest/autorun"
require "minitest/reporters"

reporters = [Minitest::Reporters::SpecReporter.new]
Minitest::Reporters.use! reporters
