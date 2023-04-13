$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "absynthe"
require "absynthe/sygus"

require "minitest/autorun"
require "minitest/reporters"
require "sxp"
require "fc"
require "timeout"
require "json"

require_relative "gc_hook"
require_relative "syn_stats_reporter"

# reporters = [Minitest::Reporters::SpecReporter.new, GCHook.new]
reporters = [Minitest::Reporters::SpecReporter.new]
reporters << SynthesisStatsReporter.new('test_log.json')
Minitest::Reporters.use! reporters

module SygusTestRunner
  def run_sygus_test(src, abs_env = nil, target_abs = nil)
    test_name = File.basename(src, '.sl').gsub('-', '_')
    define_method("test_#{test_name}") do
      # skip unless test_name == "dr_name"

      reader, writer = IO.pipe
      pid = Process.fork do
        reader.close
        ast = SXP.read_file(src)
        spec = Sygus::ProblemSpec.new(ast)
        Instrumentation.examples = spec.constraints.size

        lang = spec.lang
        constraints = spec.constraints
        abs_env = spec.init_env.map { |k, v| [k, ProductDomain.top]}.to_h if abs_env.nil?
        target_abs = ProductDomain.top if target_abs.nil?
        ctx = Context.new(abs_env, target_abs)
        Globals.root_vars = ctx.init_env.values.filter { |v| v.var? }

        ctx.cache = Cache.populate_sygus(ctx, lang) unless ENV['NO_CACHE']

        unless ENV['TEMPLATE_INFER']
          tinfer = TemplateInfer.new(ctx, constraints, spec.args)
          seed = tinfer.infer
        else
          seed = nil
        end
        seed ||= s(:hole, :Start, ctx.goal)
        # seed = s(:hole, :Start, ctx.goal)
        q = FastContainers::PriorityQueue.new(:min)
        q.push(seed, ProgSizePass.prog_size(seed))
        Timeout::timeout(10 * 60) do
          prog = synthesize(ctx, spec, q)
          Instrumentation.size = ProgSizePass.prog_size(prog)
          Instrumentation.height = ProgHeightPass.prog_height(prog)

          puts Sygus::unparse(prog)
          writer.write(Instrumentation.to_json)
          writer.close
          Process.exit 0
        end
      end
      writer.close
      Instrumentation.from_json(JSON.parse(reader.gets))
      reader.close
      Process.wait pid
    end
  end
end
