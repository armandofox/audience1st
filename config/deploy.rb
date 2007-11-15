set :application, "vbo"
#set :repository,  "file:///home/audienc/svn/vbo"
set :repository,  "svn+ssh://audienc@74.86.212.70/home/audienc/svn/vbo/trunk"
set :user, "audienc"            # defaults to the currently logged in user
ssh_options[:keys] = %w(/Users/fox/.ssh/identity)

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/audienc/rails/#{application}"
set :use_sudo, false

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "74.86.212.70"
role :web, "74.86.212.70"
role :db,  "74.86.212.70", :primary => true

deploy.task :after_update_code do
  run "chmod -R go-w #{release_path}"
  run "ln -nfs #{shared_path}/vendor #{release_path}/vendor"
  run "mv #{release_path}/config/database.yml.production #{release_path}/config/database.yml"
  run "mv #{release_path}/public/dispatch.fcgi.production #{release_path}/public/dispatch.fcgi"
end

deploy.task :restart do
  run "killall -usr1 dispatch.fcgi"
end
