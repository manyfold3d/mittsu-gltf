require "bundler/setup"

require "rspec/core"
require "rspec/core/rake_task"
require "standard/rake"
Bundler::GemHelper.install_tasks

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)

task default: :spec
