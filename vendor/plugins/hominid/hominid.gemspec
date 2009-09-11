# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{hominid}
  s.version = "1.1.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Getting"]
  s.date = %q{2009-08-11}
  s.description = %q{Hominid is a Rails GemPlugin for interacting with the Mailchimp API}
  s.email = %q{brian@terra-firma-design.com}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    "MIT-LICENSE",
     "README.textile",
     "Rakefile",
     "VERSION.yml",
     "hominid.gemspec",
     "hominid.yml.tpl",
     "init.rb",
     "install.rb",
     "lib/hominid.rb",
     "rails/init.rb",
     "test/hominid_test.rb",
     "test/test_helper.rb",
     "uninstall.rb"
  ]
  s.homepage = %q{http://github.com/bgetting/hominid}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Hominid is a Rails GemPlugin for interacting with the Mailchimp API}
  s.test_files = [
    "test/hominid_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
