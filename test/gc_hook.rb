class GCHook < Minitest::StatisticsReporter
  def before_test(test)
    GC.start
  end

  def after_test(test); end
end
