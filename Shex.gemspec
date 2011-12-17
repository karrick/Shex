# -*- encoding: utf-8 -*-
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

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
