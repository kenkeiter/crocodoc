#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--color"]
end

task :default => :spec

desc "Open an interactive Ruby (IRB) session preloaded with this library."
task :console do
  sh "irb -rubygems -r ./lib/crocodoc.rb -I ./lib"
end