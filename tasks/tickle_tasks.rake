require File.join(File.dirname(__FILE__), "../lib/tickle")
TEST_BENCHMARK_FILE_NAME = "#{RAILS_ROOT}/test_benchmark.txt"
def reset_benchmark_csv
    FileUtils.rm_rf TEST_BENCHMARK_FILE_NAME
    FileUtils.touch TEST_BENCHMARK_FILE_NAME
end

# Yanked from Rails
desc 'Run all unit, functional and integration tests'
task :tickle, :count do |t, args|
  errors = %w(tickle:units tickle:functionals tickle:integration).collect do |task|
    begin
      Rake::Task[task].invoke(args[:count])
      nil
    rescue => e
      task
    end
  end.compact
  abort "Errors running #{errors.to_sentence}!" if errors.any?
end

namespace :tickle do
  [:units, :functionals, :integration].each do |t|
    type = t.to_s.sub(/s$/, '')

    desc "Run #{type} tests"
    task t, :count do |t, args|
      Tickle.load_environment

      size = args[:count] ? args[:count].to_i : 3
      puts "Running #{type} tests using #{size} processes"
      Tickle.run_tests type, size
    end
  end
  
  
  namespace :test do
    namespace :benchmark do
      desc "Show test benchmark report"
      task :validate => :environment do
        BENCHMARK_TEST_RESULT_BORDER = "_" * 45

        unless File.zero?(TEST_BENCHMARK_FILE_NAME)

          puts BENCHMARK_TEST_RESULT_BORDER
          puts 'Error: Benchmark tests Failed. Details given below'
          puts BENCHMARK_TEST_RESULT_BORDER
          puts "Time Taken (in secs)  --  File Name"
          puts BENCHMARK_TEST_RESULT_BORDER

          File.open(TEST_BENCHMARK_FILE_NAME) do |file|
            file.each_line { |line|
              line_content =  line.split(' ')
              puts "#{line_content.first}     --     #{line_content.last}"
            }

            puts BENCHMARK_TEST_RESULT_BORDER
            abort "Failed: Current test benchmark limit is set to #{APP_CONFIG['test_limit']} seconds"
            puts BENCHMARK_TEST_RESULT_BORDER
          end
        end

        puts BENCHMARK_TEST_RESULT_BORDER
        puts "Done: Benchmark tests Successful."
        puts BENCHMARK_TEST_RESULT_BORDER
      end
    end
  end
end
