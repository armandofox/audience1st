if Rails.env == 'development'

  if Rails.version.to_i < 3
    rspec_task_source = 'spec/rake/spectask'
    rspec_task_class = 'Spec::Rake::SpecTask'
  else
    rspec_task_source = 'rspec/core/rake_task'
    rspec_task_class = 'RSpec::Core::RakeTask'
  end

  require rspec_task_source
  require 'cucumber/rake/task'

  namespace :rcov do

    rcov_opts = lambda do
      ignore_shared_traits = ENV['IGNORE_SHARED_TRAITS'].present?
      included_files = Dir['app/**/*.rb']
      included_files = included_files.reject { |path| path =~ /^app\/(models|controllers)\/shared\// } if ignore_shared_traits
      included_files = included_files.collect { |path| "^#{Regexp.quote path}$"}
      excluded_files = ['^/home', '^.bundler/', '^/usr,^spec/', '^features/']
      excluded_files += ['^app/controllers/shared/', '^app/models/shared/'] if ignore_shared_traits
      [ "--include-file #{included_files.join(',')}", # this is what we want RCov to report (comma-separated regular expressions)
        '--rails', # ignore config/, initializers/, etc.
        "--exclude #{excluded_files.join(',')}", # ignore more stuff (comma-separated regular expressions)
        '--aggregate coverage.data', # we will be running multiple processes, so we aggregate coverage data from all of them
        '-o coverage' # save the report here
      ]
    end

    Cucumber::Rake::Task.new(:cucumber) do |t|
      t.rcov = true
      t.rcov_opts = rcov_opts.call
    end

    eval(rspec_task_class).new(:rspec) do |t|
      t.rcov = true
      t.rcov_opts = rcov_opts.call
    end

    desc 'Deletes RCov artifacts'
    task :clear do
      remove_dir('coverage') if File.directory?('coverage')
      rm "coverage.data" if File.exist?("coverage.data")
    end

    desc "Generates aggregated RCov coverage for RSpec and Cucumber in /coverage"
    task :all => :clear do |t|
      puts
      puts "Compiling RSpec coverage..."
      puts "==========================="
      puts
      Rake::Task['rcov:rspec'].invoke
      puts
      puts "Compiling Cucumber coverage..."
      puts "=============================="
      puts
      Rake::Task["rcov:cucumber"].invoke
    end

  end

end
