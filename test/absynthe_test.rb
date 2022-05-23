require "test_helper"
require "sxp"
require "fc"
require "timeout"

class AbsyntheTest < Minitest::Test
  def test_that_absynthe_has_a_version_number
    refute_nil ::Absynthe::VERSION
  end
end
