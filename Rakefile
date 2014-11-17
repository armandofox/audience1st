# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
#require 'rdoc/task'


require 'tasks/rails'

# require 'metric_fu'

require 'spec/rake/spectask'
namespace :spec do 
  desc "Run specs with RCov" 
  Spec::Rake::SpecTask.new('rcov') do |t| 
    t.spec_files = FileList['spec/**/*_spec.rb'] 
    t.rcov = true 
    t.rcov_opts = ['--exclude', '\/Library\/Ruby'] 
  end 
end 
