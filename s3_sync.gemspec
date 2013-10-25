# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "s3_sync"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["oguratakayuki"]
  s.date = "2013-10-25"
  s.description = "Internationalize numbers adding normalization, validation and modifying the number field to restor the value to its original if validation fails"
  s.email = ["otn.ogura@gmail.com"]
  s.executables = ["s3_sync"]
  s.files = [".gitignore", "Gemfile", "LICENSE.txt", "README.md", "Rakefile", "bin/s3_sync", "lib/s3_sync.rb", "lib/s3_sync/acl_manager.rb", "lib/s3_sync/cli.rb", "lib/s3_sync/file_manager.rb", "lib/s3_sync/s3_strategy.rb", "lib/s3_sync/version.rb", "s3_sync.gemspec"]
  s.homepage = ""
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "Internationalize numbers adding normalization, validation and modifying the number field to restor the value to its original if validation fails"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
      s.add_runtime_dependency(%q<aws-sdk>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<aws-sdk>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<aws-sdk>, [">= 0"])
  end
end
