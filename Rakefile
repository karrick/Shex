require "rubygems"
require "bundler/gem_tasks"

desc "Test module"
task :test do
  Dir.glob("test/test*.rb").each do |test_file|
    system("ruby", test_file)
  end
end
