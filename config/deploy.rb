abort "Must set '-Svenue=venuename'" unless venue = variables[:venue]

set :venue, variables[:venue]
set :from, variables[:from]
set :rails_root, "#{File.dirname(__FILE__)}/.."
set :config, (:venue ? (YAML::load(IO.read("#{rails_root}/config/venues.yml")))[venue] : {} )

set :debugging_ips, %w[67.169.93.204]

set :application,     "vbo"
set :user,            "audienc"
set :home,            "/home/#{user}"
set :deploy_to,       "#{home}/rails/#{venue}"
set :stylesheet_dir,  "#{home}/public_html/stylesheets"
set :use_sudo,        false
set :host,            "audience1st.com"
role :app,            "#{host}"
role :web,            "#{host}"
role :db,             "#{host}", :primary => true
set :base_repository, "svn+ssh://#{user}@#{host}/#{home}/svn/#{application}"



if variables[:tag]
  # to deploy from a tag, run 'cap -Stag=tagname -Svenue=venuename deploy'
  set :repository,    "#{base_repository}/tags/#{variables[:tag]}"
elsif variables[:branch]
  # to deploy from branch, 'cap -Sbranch=branchname -Svenue=venuename deploy'
  set :repository,    "#{base_repository}/branches/#{variables[:branch]}"
else
  set :repository,    "#{base_repository}/trunk"
end
ssh_options[:keys] = %w(/Users/fox/.ssh/identity)

# run migrations in a separate environment, so they can use a different
# DB user
deploy.task :migrate, :roles => [:db] do
  run "cd #{release_path} && rake db:migrate RAILS_ENV=migration"
end

namespace :provision do
  task :create_database do
    "For new venue, create new database and user, and grant migration privileges to migration user.  Set venue password in venues.yml first."
    abort "Need MySQL root password" unless (pass = variables[:password])
    mysql = "mysql -uroot '-p#{pass}' -e \"%s;\""
    run (mysql % "create database #{venue}")
    run (mysql % "create user '#{venue}'@'localhost' identified by '#{venuepass}'")
    run (mysql % "grant select,insert,update,delete,lock on #{venue}.* to '#{venue}'@'localhost'")
    run "ln -s #{home}/rails/#{venue}/current/public #{home}/public_html"
    # still need to link stylesheets
  end

  #  NEED A TASK TO SETUP THE VIRTUAL SERVER ENTRIES FOR PHUSION PASSENGER
  #  add to end of  /usr/local/apache/conf/httpd.conf:  RailsBaseURI /venuename
  #  then restart apache
  
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
    run "cd #{init_release_path} && script/runner -e production 'Customer.create!(:first_name => \"Administrator\", :last_name => \"Administrator\", :email => \"admin\", :password => \"admin\", :created_by_admin => true)"
    run "cd #{init_release_path} && script/runner -e production 'Customer.find_by_email('admin').update_attribute(:role, 100)'"
    ## need to wipe out Options table values here
  end
end

namespace :deploy do
  desc "Clear all sessions from DB, in case of change in session schema."
  task :clear_sessions do
    run "cd #{deploy_to}/current && RAILS_ENV=production rake db:sessions:clear"
  end
end

namespace :deploy do
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

deploy.task :after_update_code do
  # prepend branch base rev into REVISION file
  if variables[:branch] =~ /-r([0-9]+)/
    put "#{$1}.#{real_revision}", "#{release_path}/REVISION"
  end
  # make logfile and tmp dir (for attachments) publicly writable, for use by daemons
  run "touch #{release_path}/log/production.log"
  run "chmod 0666 #{release_path}/log/production.log"
  run "chmod 0777 #{release_path}/tmp"
  # create database.yml
  # copy installation-specific files
  config = (YAML::load(IO.read("#{rails_root}/config/venues.yml")))[venue]
  abort if (config.nil? || config.empty?)
  debugging_ips = variables[:debugging_ips]
  %w[config/database.yml config/facebooker.yml config/newrelic.yml public/.htaccess support/Makefile].each do |f|
    file = ERB.new(IO.read("#{rails_root}/#{f}.erb")).result(binding)
    put file, "#{release_path}/#{f}"
    run "rm -f #{release_path}/#{f}.erb"
  end    
  # make public/stylesheets/venue point to venue's style assets
  run "ln -s #{stylesheet_dir}/#{venue}  #{release_path}/public/stylesheets/venue"
  # similarly, link favicon.ico
  run "rm -f #{release_path}/public/favicon.ico && ln -s #{stylesheet_dir}/#{venue}/favicon.ico #{release_path}/public/"
  %w[config/venues.yml manual doc spec features].each { |dir|  run "rm -rf #{release_path}/#{dir}" }
  run "chmod -R go-w #{release_path}"
end

deploy.task :restart do
  run "touch #{release_path}/tmp/restart.txt"
end

