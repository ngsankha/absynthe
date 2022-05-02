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
      GC.start
      # skip unless test_name == "phone_9"

      ast = SXP.read_file(src)
      spec = Sygus::ProblemSpec.new(ast)
      lang = spec.lang
      constraints = spec.constraints
      abs_env = spec.init_env.map { |k, v| [k, ProductDomain.top]}.to_h if abs_env.nil?
      target_abs = ProductDomain.top if target_abs.nil?
      ctx = Context.new(abs_env, target_abs)
      Globals.root_vars = ctx.init_env.values.filter { |v| v.var? }

      tinfer = TemplateInfer.new(ctx, constraints, spec.args)
      seed = tinfer.infer
      seed ||= s(:hole, :Start, ctx.goal)
      # seed = s(:send, :"str.substr",
      #       s(:const, :name),
      #       s(:hole, :ntInt, ctx.domain.fresh_var),
      #       s(:dephole, :ntInt, ctx.domain.fresh_var))
      q = FastContainers::PriorityQueue.new(:min)
      q.push(seed, ProgSizePass.prog_size(seed))
      Timeout::timeout(5 * 60) do
        prog = synthesize(ctx, spec, q)
        puts Sygus::unparse(prog)
      end
    end
  end
end
