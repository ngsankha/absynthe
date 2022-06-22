$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "absynthe"
require "absynthe/sygus"

require "minitest/autorun"
require "minitest/reporters"
require "sxp"
require "fc"
require "timeout"

require_relative "gc_hook"
require_relative "syn_stats_reporter"

reporters = [Minitest::Reporters::SpecReporter.new, GCHook.new]
reporters << SynthesisStatsReporter.new('test_log.json')
Minitest::Reporters.use! reporters

module SygusTestRunner
  def run_sygus_test(src, abs_env = nil, target_abs = nil)
    test_name = File.basename(src, '.sl').gsub('-', '_')
    define_method("test_#{test_name}") do
      skip unless test_name == "bikes"

      ast = SXP.read_file(src)
      spec = Sygus::ProblemSpec.new(ast)
      Instrumentation.examples = spec.constraints.size

      lang = spec.lang
      constraints = spec.constraints
      abs_env = spec.init_env.map { |k, v| [k, ProductDomain.top]}.to_h if abs_env.nil?
      target_abs = ProductDomain.top if target_abs.nil?
      ctx = Context.new(abs_env, target_abs)
      Globals.root_vars = ctx.init_env.values.filter { |v| v.var? }

      # ctx.cache = Cache.populate_sygus(ctx, lang)

      tinfer = TemplateInfer.new(ctx, constraints, spec.args)
      seed = tinfer.infer
      seed ||= s(:hole, :Start, ctx.goal)
      # seed = s(:hole, :Start, ctx.goal)
      q = FastContainers::PriorityQueue.new(:min)
      q.push(seed, ProgSizePass.prog_size(seed))
      Timeout::timeout(10 * 60) do
        prog = synthesize(ctx, spec, q)
        Instrumentation.prog = prog

        puts Sygus::unparse(prog)
      end
    end
  end
end
