require 'json'

class SynthesisStatsReporter < Minitest::StatisticsReporter
  def initialize(path)
    super
    @path = path
    @results_agg = {}
  end

  def before_test(test)
    Instrumentation.reset!
  end

  def after_test(test)
    return unless test.passed?
  end

  def record(result)
    @results_agg[result.name] = {
      time: result.passed? ? result.time : "-",
      size: Instrumentation.size,
      specs: Instrumentation.examples,
      gc_time: Instrumentation.gc_time,
      tested_progs: Instrumentation.tested_progs,
      domain: Instrumentation.domain
    }
  end

  def report
    File.write(@path, @results_agg.to_json)
  end
end
