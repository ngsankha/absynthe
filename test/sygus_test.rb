require "test_helper"
require "sxp"
require "fc"
require "timeout"

class SygusTest < Minitest::Test
  def test_dr_name
    ast = SXP.read_file('./sygus-strings/dr-name.sl')
    spec = Sygus::ProblemSpec.new(ast)
    lang = spec.lang
    constraints = spec.constraints
    ctx = Context.new({:name => Sygus::StringPrefix.top}, Sygus::StringPrefix.val("Dr. ", false))

    seed = s(:hole, :Start, ctx.goal)
    q = FastContainers::PriorityQueue.new(:min)
    q.push(seed, ProgSizePass.prog_size(seed))
    Timeout::timeout(5 * 60) do
      prog = synthesize(ctx, spec, q)
      puts Sygus::unparse(prog)
    end
    assert true
  end

  def test_bikes
    ast = SXP.read_file('./sygus-strings/bikes.sl')
    spec = Sygus::ProblemSpec.new(ast)
    lang = spec.lang
    constraints = spec.constraints
    ctx = Context.new({:name => Sygus::StringPrefix.top}, Sygus::StringPrefix.top)

    seed = s(:hole, :Start, ctx.goal)
    q = FastContainers::PriorityQueue.new(:min)
    q.push(seed, ProgSizePass.prog_size(seed))
    Timeout::timeout(5 * 60) do
      prog = synthesize(ctx, spec, q)
      puts Sygus::unparse(prog)
    end
    assert true
  end

  def test_phone
    ast = SXP.read_file('./sygus-strings/phone.sl')
    spec = Sygus::ProblemSpec.new(ast)
    lang = spec.lang
    constraints = spec.constraints
    ctx = Context.new({:name => Sygus::StringPrefix.top}, Sygus::StringPrefix.top)

    seed = s(:hole, :Start, ctx.goal)
    q = FastContainers::PriorityQueue.new(:min)
    q.push(seed, ProgSizePass.prog_size(seed))
    Timeout::timeout(5 * 60) do
      prog = synthesize(ctx, spec, q)
      puts Sygus::unparse(prog)
    end
    assert true
  end

  def test_phone_2
    ast = SXP.read_file('./sygus-strings/phone-2.sl')
    spec = Sygus::ProblemSpec.new(ast)
    lang = spec.lang
    constraints = spec.constraints
    ctx = Context.new({:name => Sygus::StringPrefix.top}, Sygus::StringPrefix.top)

    seed = s(:hole, :Start, ctx.goal)
    q = FastContainers::PriorityQueue.new(:min)
    q.push(seed, ProgSizePass.prog_size(seed))
    Timeout::timeout(5 * 60) do
      prog = synthesize(ctx, spec, q)
      puts Sygus::unparse(prog)
    end
    assert true
  end

  def test_firstname
    ast = SXP.read_file('./sygus-strings/firstname.sl')
    spec = Sygus::ProblemSpec.new(ast)
    lang = spec.lang
    constraints = spec.constraints
    ctx = Context.new({:name => Sygus::StringPrefix.top}, Sygus::StringPrefix.top)

    seed = s(:hole, :Start, ctx.goal)
    q = FastContainers::PriorityQueue.new(:min)
    q.push(seed, ProgSizePass.prog_size(seed))
    Timeout::timeout(5 * 60) do
      prog = synthesize(ctx, spec, q)
      puts Sygus::unparse(prog)
    end
    assert true
  end
end
