require "bundler/gem_tasks"

gem 'rspec'
require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

######################################################################

desc "Default => :test"
task :default => :test

desc "Run all tests"
task :test => [ :spec ]

desc "Run examples."
task :example do
  ENV["ASIR_EXAMPLE_SILENT"]="1"
  Dir["example/ex[0-9]*.rb"].each do | rb |
    sh %Q{ruby -I example -I lib #{rb}}
  end
  ENV.delete("ASIR_EXAMPLE_SILENT")
end

######################################################################

desc "Install system prerequites"
task :prereq do
  case RUBY_PLATFORM
  when /darwin/i
    sh "sudo port install beanstalkd"
  when /linux/i
    sh "sudo apt-get install beanstalkd"
  end
end
