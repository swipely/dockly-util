# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dockly/util/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Swipely, Inc."]
  gem.email         = %w{tomhulihan@swipely.com bright@swipely.com toddlunter@swipely.com}
  gem.description   = %q{DSL made easy}
  gem.summary       = %q{DSL made easy}
  gem.homepage      = "https://github.com/swipely/dockly-util"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dockly-util"
  gem.require_paths = %w{lib}
  gem.version       = Dockly::Util::VERSION
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'cane'
  gem.add_development_dependency 'pry'
end
