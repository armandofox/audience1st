# automatically run 'bundle install' to put bundled gems into vendor/ on deploy
require 'bundler/capistrano'
set :bundle_flags, '--deployment'
set :bundle_without, [:development, :test]
# so capistrano can find 'bundle' binary...
set :default_environment, {
  'PATH' => "/opt/ruby-enterprise-1.8.7-2012.02/bin:$PATH"
}

# automatically run 'bundle install' to put bundled gems into vendor/ on deploy
require 'bundler/capistrano'
set :bundle_flags, '--deployment'
set :bundle_without, [:development, :test]
# so capistrano can find 'bundle' binary...
set :default_environment, {
  'PATH' => "/opt/ruby-enterprise-1.8.7-2012.02/bin:$PATH"
}

set :venue, variables[:venue]
set :from, variables[:from]
set :rails_root, "#{File.dirname(__FILE__)}/.."
set :config, (:venue ? (YAML::load(IO.read("#{rails_root}/config/venues.yml")))[venue] : {} )

set :debugging_ips, %w[199.116.74.100]

set :application,     "audience1st"
set :user,            "audienc"
set :home,            "/home/#{user}"
set :deploy_to,       "#{home}/rails/#{venue}"
set :stylesheet_dir,  "#{home}/public_html/stylesheets"
set :venue_config,    "#{home}/vboadmin/venues.yml"
set :use_sudo,        false
set :host,            "audience1st.com"
role :app,            "#{host}"
role :web,            "#{host}"
role :db,             "#{host}", :primary => true

set :repository, 'git@github.com:armandofox/audience1st.git'
set :scm, :git
set :deploy_via, :remote_cache
set :branch, (variables[:branch] || 'master')
ssh_options[:keys] = %w(/Users/fox/.ssh/identity)
ssh_options[:forward_agent] = true

namespace :provision do
  abort "Must set '-Svenue=venuename'" unless venue = variables[:venue]
  task :create_database do
    "For new venue, create new database and user, and grant migration privileges to migration user.  Set venue password in venues.yml first."
    abort "Need MySQL root password" unless (pass = variables[:password])
    venuepass = config['password']
    abort "Need to set venue password in venues.yaml" unless venuepass.to_s != ''
    mysql = "mysql -uroot '-p#{pass}' -e \"%s;\""
    run (mysql % "create database #{venue}")
    run (mysql % "create user '#{venue}'@'localhost' identified by '#{venuepass}'")
    run (mysql % "grant select,insert,update,delete,lock tables on #{venue}.* to '#{venue}'@'localhost'")
  end

  task :initial_deploy do
    "Setup symlinks etc for initial deployment of new venue"
    run "ln -s #{home}/rails/#{venue}/current/public #{home}/public_html"
  end

  task :truncate_database, :roles => [:db] do
    "Truncate all non-static DB tables and wipe out sensitive Options"
    drop_all = %w(bulk_downloads customers customers_labels imports items labels sessions showdates shows txns valid_vouchers visits vouchertypes).map do |tbl|
      "truncate table #{tbl}"
    end.join("; ")
    run  "mysql -umigration -pm1Gr4ti0N -D#{venue} -e \"#{drop_all};\""
    init_release_path = "#{home}/rails/#{venue}/current"
    run %Q{cd #{init_release_path} && script/runner -e production 'Customer.create!(:first_name => "Administrator", :last_name => "Administrator", :email => "admin@#{venue}.org", :password => "admin", :created_by_admin => true).update_attribute(:role, 100)'}
    run %Q{cd #{init_release_path} && script/runner -e production 'Option.update_all(:value => ""); Option.set_value!(:venue_shortname, "#{venue}")'}
  end
  
  # initialize DB by copying schema and static content from a (production)
  # source  DB
  task :initialize_database, :roles => [:db] do
    "Set up database (must exist already; use provision:create_database) for new venue by copying static structure and Options table from -Sfrom=<venue>."
    abort "Must set from name with -Sfrom=<venue>" unless variables[:from]
    init_release_path = "#{home}/rails/#{venue}/current"
    tmptables = "#{init_release_path}/db/static_tables.sql"
    config = (YAML::load(IO.read("#{rails_root}/config/venues.yml")))[venue]
    db = config['db'] || venue
    run "cd #{home}/rails/#{from}/current && rake db:schema:dump RAILS_ENV=migration && mv db/schema.rb #{init_release_path}/db/schema.rb"
    run "cd #{home}/rails/#{from}/current && rake db:dump_static RAILS_ENV=migration FILE=#{tmptables}"
    run "cd #{init_release_path} && rake db:schema:load RAILS_ENV=migration"
    run "mysql -umigration -pm1Gr4ti0N -D#{db} < #{tmptables}"
    run "/bin/rm -f #{tmptables}"
    Rake::Task['provision:truncate_database'].execute
  end
end

namespace :deploy do
  abort "Must set '-Svenue=venuename'" unless venue = variables[:venue]

  desc "Clear all sessions from DB, in case of change in session schema."
  task :clear_sessions do
    run "cd #{deploy_to}/current && RAILS_ENV=production rake db:sessions:clear"
  end

  desc "Run migrations in a separate 'migration' environment, so they can use a different DB user"
  task :migrate, :roles => [:db] do
    run "cd #{release_path} && rake db:migrate RAILS_ENV=migration"
  end

  desc "Restart all appserver processes on next request"
  task :restart do
    run "touch #{current_release}/tmp/restart.txt"
    # touch the server to spin it up
    run "wget --no-check-certificate -o /dev/null -O /dev/null http://www.audience1st.com/#{venue}/store"
  end

  desc "Clean up deployment by removing unnecessary files from production env"
  after 'deploy:update_code' do
    # truncate REVISION to 6-hex-digit prefix
    run "perl -pi -e 's/^(......).*\$/\\1/g' #{release_path}/REVISION"
    # copy installation-specific files
    config = (YAML::load(IO.read(venue_config)))[venue]
    abort if (config.nil? || config.empty?)
    debugging_ips = variables[:debugging_ips]
    %w[config/database.yml public/.htaccess].each do |f|
      file = ERB.new(IO.read("#{rails_root}/#{f}.erb")).result(binding)
      put file, "#{release_path}/#{f}"
      run "rm -f #{release_path}/#{f}.erb"
    end    
    # make public/stylesheets/venue point to venue's style assets
    run "ln -s #{stylesheet_dir}/#{venue}  #{release_path}/public/stylesheets/venue"
    # similarly, link favicon.ico
    run "rm -f #{release_path}/public/favicon.ico && ln -s #{stylesheet_dir}/#{venue}/favicon.ico #{release_path}/public/"
    %w[spec features].each { |dir|  run "rm -rf #{release_path}/#{dir}" }
    run "chmod -R go-w #{release_path}"
    # make logfile and tmp dir (for attachments) publicly writable, for use by daemons
    run "touch #{release_path}/log/production.log"
    run "chmod 0666 #{release_path}/log/production.log"
    run "chmod 0777 #{release_path}/tmp"
  end


  namespace :web do
    desc "Protect app by requiring valid-user in htaccess."
    task :protect do
      run "perl -pi -e 's/^\s*#\s*require\s*valid-user/require valid-user/' #{deploy_to}/current/public/.htaccess"
    end
    desc "Unprotect app by NOT requiring valid-user in htaccess."
    task :unprotect do
      run "perl -pi -e 's/^\s*require\s*valid-user/# require valid-user/' #{deploy_to}/current/public/.htaccess"
    end
  end
end
