#!/usr/bin/env rake

require 'rake'
require 'rspec/core/rake_task'


# run 'rspec' to test against latest activerecord
# run 'rake' to test against all supported versions

RSpec::Core::RakeTask.new :spec4

task :spec3 do
  system('BUNDLE_GEMFILE=Gemfile-AR3 bundle install')
  system('BUNDLE_GEMFILE=Gemfile-AR3 bundle exec rspec')
end

task :spec => ['spec4', 'spec3']

task :default => ['spec']
task :test => ['spec']


task :console do
  chdir File.dirname(__FILE__)
  exec 'irb -I lib/ -r richfield'
end


task :build  do
  system 'gem build richfield.gemspec'
end

task :release do
  system 'gem push richfield-*.gem'
end
