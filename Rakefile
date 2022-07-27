# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'
require 'yard/rake/yardoc_task'
require 'code_statistics'
require 'version'
require 'rake/version_task'
require 'rubocop//rake_task'

Rake::VersionTask.new
RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)

task default: :spec

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', '-', 'doc/**/*', 'spec/**/*_spec.rb']
  t.options += ['-o', 'yardoc']
end
YARD::Config.load_plugin('yard-rspec')

namespace :yardoc do
  task :clobber do
    begin
      rm_r 'yardoc'
    rescue StandardError
      nil
    end
    begin
      rm_r '.yardoc'
    rescue StandardError
      nil
    end
    begin
      rm_r 'pkg'
    rescue StandardError
      nil
    end
  end
end

task clobber: 'yardoc:clobber'
