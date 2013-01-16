# -*- encoding: utf-8 -*-
# -*- ruby -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'asir_beanstalk/version'

Gem::Specification.new do |gem|
  gem.name          = "asir_beanstalk"
  gem.version       = AsirBeanstalk::VERSION
  gem.authors       = ["Kurt Stephens"]
  gem.email         = ["ks.github@kurtstephens.com"]
  gem.description   = %q{Beanstalkd transport for ASIR}
  gem.summary       = %q{Beanstalkd transport for ASIR}
  gem.homepage      = "http://github.com/kstephens/abstracting_services_in_ruby"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "asir", "~> 1.2.3"

  gem.add_development_dependency 'rake', '>= 0.9.0'
  gem.add_development_dependency 'rspec', '~> 2.12.0'
  gem.add_development_dependency 'simplecov', '>= 0.1'
end
