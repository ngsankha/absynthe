require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:bench) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/sygus_bench.rb"]
end

Rake::TestTask.new(:smallbench) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/sygus_small_bench.rb"]
end

task :default => :test
