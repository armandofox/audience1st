abort "Must set '-Svenue=venuename'" unless venue = variables[:venue]

set :application,     "vbo"
set :user,            "audienc"
set :home,            "/home/#{user}"
set :deploy_to,       "#{home}/rails/#{venue}"
set :use_sudo,        false
set :host,            "audience1st.com"
#set :host, "74.63.14.66"
role :app,            "#{host}"
role :web,            "#{host}"
role :db,             "#{host}", :primary => true
#set :base_repository, "svn+ssh://#{user}@#{host}/#{home}/svn/#{application}"
set :base_repository, "svn+ssh://audienc@audience1st.com/home/audienc/svn/vbo"

if variables[:tag]
  # to deploy from a tag, run 'cap -Stag=tagname -Svenue=venuename deploy'
  set :repository,    "#{base_repository}/tags/#{variables[:tag]}"
elsif variables[:branch]
  # to deploy from a branch, run 'cap -Sbranch=branchname -Svenue=venuename deploy'
  set :repository,    "#{base_repository}/branches/#{variables[:branch]}"
else
  set :repository,    "#{base_repository}/trunk"
end
ssh_options[:keys] = %w(/Users/fox/.ssh/identity)

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
  run "chmod -R go-w #{release_path}"
  #run "ln -nfs #{shared_path}/vendor #{release_path}/vendor"
  # copy installation-specific files
  %w[public/.htaccess config/database.yml].each do |file|
    run "mv #{release_path}/#{file}.#{venue}  #{release_path}/#{file}"
    run "rm -rf #{release_path}/#{file}.*"
  end
  %w[manual doc test].each { |dir|  run "rm -rf #{release_path}/#{dir}" }
end

deploy.task :restart do
  run "touch #"
  run "killall -usr1 dispatch.fcgi >& /dev/null"
end
