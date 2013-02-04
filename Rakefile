require "rubygems"
require "bundler/gem_tasks"
require 'rake/clean'

CLEAN.include('pkg')

desc "Test module"
task :test do
  failure_detected = false
  Dir.glob("test/test*.rb").each do |test_file|
    failure_detected = true unless system("ruby", test_file)
  end
  exit 1 if failure_detected
end
