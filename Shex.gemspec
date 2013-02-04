# -*- mode: ruby -*-

$:.push File.expand_path("../lib", __FILE__)
require "Shex/version"

Gem::Specification.new do |s|
  s.name        = "Shex"
  s.version     = Shex::VERSION
  s.authors     = ["Karrick McDermott"]
  s.email       = ["karrick@karrick.net"]
  s.homepage    = ""
  s.summary     = %q{Shell invocation library}
  s.description = %q{Some useful--to me at least--methods for controlling child processes invoked using the shell.  Can be used to run local and remote processes, as current user or a different user.}

  s.rubyforge_project = "Shex"

  s.files         = Dir.glob("{bin,lib}/**/*") + %w(README)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
