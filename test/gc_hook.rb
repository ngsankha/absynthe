class GCHook < Minitest::StatisticsReporter
  def before_test(test)
    start = Time.now
    GC.start
    finish = Time.now
    Instrumentation.gc_time = finish - start
  end

  def after_test(test); end
end
