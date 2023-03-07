require "test_helper"

## No way to propagate information to other types. Predicate domain needed?

class SygusTest < Minitest::Test
  extend SygusTestRunner

  run_sygus_test('./sygus-strings/bikes.sl')
  run_sygus_test('./sygus-strings/lastname.sl')
  run_sygus_test('./sygus-strings/phone-2.sl')
end
