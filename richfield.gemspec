# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = 'richfield'
  s.version  = '0.0.1'
  s.authors  = ['Scott Bronson']
  s.email    = ['brons_richfield@rinspin.com']
  s.homepage = 'http://github.com/bronson/richfield'
  s.summary  = 'Have your models write your migrations'
  s.description = 'Put your models in charge. Show them how to write your Rails migrations for you.'

  s.require_paths = ['lib']
  s.files = Dir['README.markdown', 'lib/**/*', 'Gemfile', 'Rakefile']
  s.test_files = Dir['spec/**/*']

  s.add_development_dependency 'rspec', ['>= 2.5']
  s.add_runtime_dependency 'activerecord', ['>= 3.0']
  s.license = 'MIT'
end
