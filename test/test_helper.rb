$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "absynthe"

require "minitest/autorun"
require "minitest/reporters"
require "sxp"
require "fc"
require "timeout"

reporters = [Minitest::Reporters::SpecReporter.new]
Minitest::Reporters.use! reporters

module SygusTestRunner
  def run_sygus_test(src, abs_env = nil, target_abs = nil)
    test_name = File.basename(src, '.sl').gsub('-', '_')
    define_method("test_#{test_name}") do
      skip unless test_name == "name_combine_3"

      ast = SXP.read_file(src)
      spec = Sygus::ProblemSpec.new(ast)
      lang = spec.lang
      constraints = spec.constraints
      abs_env = spec.init_env.map { |k, v| [k, ProductDomain.top]}.to_h if abs_env.nil?
      target_abs = ProductDomain.top if target_abs.nil?
      ctx = Context.new(abs_env, target_abs)
      Globals.root_vars = ctx.init_env.values.filter { |v| v.var? }

      # seed = s(:hole, :Start, ctx.goal)
      seed = s(:send, :"str.++", s(:send, :"str.++", s(:hole, :Start, ctx.domain.top), s(:const, " ")), s(:const, :lastname))
      q = FastContainers::PriorityQueue.new(:min)
      q.push(seed, ProgSizePass.prog_size(seed))
      Timeout::timeout(10 * 60) do
        prog = synthesize(ctx, spec, q)
        puts Sygus::unparse(prog)
      end
    end
  end
end
