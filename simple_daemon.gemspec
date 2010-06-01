# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{simple_daemon}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["watsonian"]
  s.date = %q{2010-06-01}
  s.description = %q{A simple library for daemonizing scripts.}
  s.email = %q{watsonian@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/simple_daemon.rb",
     "simple_daemon.gemspec",
     "test/helper.rb",
     "test/test_simple_daemon.rb"
  ]
  s.homepage = %q{http://github.com/watsonian/simple_daemon}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A simple library for daemonizing scripts.}
  s.test_files = [
    "test/helper.rb",
     "test/test_simple_daemon.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<simple_pid>, [">= 0.1.0"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<simple_pid>, [">= 0.1.0"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<simple_pid>, [">= 0.1.0"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end
