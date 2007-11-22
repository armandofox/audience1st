set :application,     "vbo"
set :user,            "audienc"
set :home,            "/home/#{user}"
set :deploy_to,       "#{home}/rails/#{application}"
set :use_sudo,        false
set :host,            "audience1st.com"
role :app,            "#{host}"
role :web,            "#{host}"
role :db,             "#{host}", :primary => true
set :base_repository, "svn+ssh://#{user}@#{host}/#{home}/svn/#{application}"
if variables[:tag]
  set :repository,    "#{base_repository}/tags/#{variables[:tag]}"
elsif variables[:branch]
  set :repository,    "#{base_repository}/branches/#{variables[:branch]}"
else
  set :repository,    "#{base_repository}/trunk"
end
ssh_options[:keys] = %w(/Users/fox/.ssh/identity)

deploy.task :after_update_code do
  run "chmod -R go-w #{release_path}"
  #run "ln -nfs #{shared_path}/vendor #{release_path}/vendor"
  run "mv #{release_path}/config/database.yml.production #{release_path}/config/database.yml"
  run "mv #{release_path}/public/dispatch.fcgi.production #{release_path}/public/dispatch.fcgi"
end

deploy.task :restart do
  run "killall -usr1 dispatch.fcgi >& /dev/null"
end
