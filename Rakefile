#!/usr/bin/env rake

require File.expand_path('../config/application', __FILE__)
Richfield::Application.load_tasks

# it's MUCH faster (~8X) to just call rspec since all Rails doesn't have to be loaded
task :default => ['spec']
task :test => ['spec']
task :spec do system "rspec" end
