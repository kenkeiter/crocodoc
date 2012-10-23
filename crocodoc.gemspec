# -*- encoding: utf-8 -*-
require File.expand_path('../lib/crocodoc/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kenneth Keiter"]
  gem.email         = ["ken@kenkeiter.com"]
  gem.description   = %q{Provides a clean, object-oriented interface to the Crocodoc API.}
  gem.summary       = %q{Provides a clean, object-oriented interface to the Crocodoc API.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "crocodoc"
  gem.require_paths = ["lib"]
  gem.version       = Crocodoc::VERSION

  gem.add_dependency 'faraday'
  gem.add_dependency 'faraday_middleware'
  gem.add_dependency 'mime-types'
  gem.add_dependency 'multi_json'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-bundler'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rb-fsevent', '~> 0.9.1'

end
