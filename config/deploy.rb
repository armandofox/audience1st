abort "run with 'cap _1.4.1_ [task]'" if respond_to?(:namespace) 

# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "vbo"
set :repository, ":ext:audience@audience1st.com:/home/audience/CVS/"


# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :web, "audience1st.com"
role :app, "audience1st.com"
role :db,  "audience1st.com", :primary => true


# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, "/home/audience/rails/#{application}"
set :user, "audience"            # defaults to the currently logged in user
set :scm, :cvs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway
set :use_sudo, false

# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:keys] = %w(/Users/fox/.ssh/identity)
# ssh_options[:port] = 25

#
#  Other variables
#

public_html = "/home/audience/public_html"
stage_ptr = "altarena-test"
release_ptr = "altarena"
db_backup_dir = "/home/audience/backup"

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

desc <<DESC
An imaginary backup task. (Execute the 'show_tasks' task to display all
available tasks.)
DESC
task :backup, :roles => :db, :only => { :primary => true } do
  # the on_rollback handler is only executed if this task is executed within
  # a transaction (see below), AND it or a subsequent task fails.
  on_rollback { delete "/tmp/dump.sql" }

  run "mysqldump -u theuser -p thedatabase > /tmp/dump.sql" do |ch, stream, out|
    ch.send_data "thepassword\n" if out =~ /^Enter password:/
  end
end

# Tasks may take advantage of several different helper methods to interact
# with the remote server(s). These are:
#
# * run(command, options={}, &block): execute the given command on all servers
#   associated with the current task, in parallel. The block, if given, should
#   accept three parameters: the communication channel, a symbol identifying the
#   type of stream (:err or :out), and the data. The block is invoked for all
#   output from the command, allowing you to inspect output and act
#   accordingly.
# * sudo(command, options={}, &block): same as run, but it executes the command
#   via sudo.
# * delete(path, options={}): deletes the given file or directory from all
#   associated servers. If :recursive => true is given in the options, the
#   delete uses "rm -rf" instead of "rm -f".
# * put(buffer, path, options={}): creates or overwrites a file at "path" on
#   all associated servers, populating it with the contents of "buffer". You
#   can specify :mode as an integer value, which will be used to set the mode
#   on the file.
# * render(template, options={}) or render(options={}): renders the given
#   template and returns a string. Alternatively, if the :template key is given,
#   it will be treated as the contents of the template to render. Any other keys
#   are treated as local variables, which are made available to the (ERb)
#   template.

desc "Restart the app"
task :restart, :roles => :app do
  run "killall -9 ruby"
end

desc "Demonstrates the various helper methods available to recipes."
task :helper_demo do
  # "setup" is a standard task which sets up the directory structure on the
  # remote servers. It is a good idea to run the "setup" task at least once
  # at the beginning of your app's lifetime (it is non-destructive).
  setup

  buffer = render("maintenance.rhtml", :deadline => ENV['UNTIL'])
  put buffer, "#{shared_path}/system/maintenance.html", :mode => 0644
  sudo "killall -USR1 dispatch.fcgi"
  run "#{release_path}/script/spin"
  delete "#{shared_path}/system/maintenance.html"
end

# You can use "transaction" to indicate that if any of the tasks within it fail,
# all should be rolled back (for each task that specifies an on_rollback
# handler).

desc "A task demonstrating the use of transactions."
task :long_deploy do
  transaction do
    update_code
    disable_web
    symlink
    migrate
  end

  restart
  enable_web
end

desc "Stage latest version on production server."
task :stage do
  update_code
  run "rm #{public_html}/#{stage_ptr}"
  run "ln -nfs #{release_path}/public/ #{public_html}/#{stage_ptr}"
  run "cd #{release_path}/.. && rm stage && ln -s #{release_path} stage"
end

task :quick_release do
  update_code
  symlink
  migrate
  restart
end

task :make_release do
  run "sed -i -e '/RAILS_ENV.*production/s/^# +[^#]//' #{release_path}/config/environment.rb"
end

task :flip do
  # adjust RAILS_ENV pointer on stage copy
  # stop app
  # run migration on production DB
  # flip pointer
  # start app
end

task :patch do
  run "cd #{release_path} && cvs update"
end

task :after_update_code do
  run "chmod -R go-w #{release_path}"
  run "ln -nfs #{shared_path}/vendor #{release_path}/vendor"
end

task :backup_db do
  tmpfile = Time.now.strftime("%Y%m%d%H%M%S")
  run "mysqldump -uaudience_admin '-p,rtto;u' audience_vboproduction | gzip > #{db_backup_dir}/#{tmpfile}.gz"
end

task :copy_db do
  run "mysqldump -uaudience_admin '-p,rtto;u' audience_vboproduction | mysql  -uaudience_admin '-p,rtto;u' --database=audience_vbodevelopment --batch" 
end
