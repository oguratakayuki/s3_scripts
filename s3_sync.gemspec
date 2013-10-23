# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's3_sync/version'

Gem::Specification.new do |spec|
  spec.name          = "s3_sync"
  spec.version       = S3Sync::VERSION
  spec.authors       = ["oguratakayuki"]
  spec.email         = ["otn.ogura@gmail.com"]
  spec.description   = %q{Internationalize numbers adding normalization, validation and modifying the number field to restor the value to its original if validation fails}
  spec.summary       = spec.description 
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency 'thor'
  spec.add_dependency 'aws-sdk'
end
