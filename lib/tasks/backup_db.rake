namespace :db do
  desc "Dump DB corresponding to RAILS_ENV to ENV[FILE] or an auto-generated filename"
  task :dump => :environment do
    cmd = retrieve_db_info
    archive = ENV['FILE'] || Time.now.strftime("%Y%m%d-%H%M%S.sql")
    cmd = "mysqldump --opt --skip-add-locks #{cmd} > #{archive}"
    puts "Dumping #{RAILS_ENV} database to #{archive} using command:"
    puts cmd
    result = system(cmd)
    raise("mysqldump failed: #{$?}") unless result
  end

  desc "Restore DB corresponding to RAILS_ENV from ENV[FILE] or STDIN"
  task :restore => :environment do
    opts = retrieve_db_info
    #raise "Must set FILE=filename to restore from" unless file = ENV['FILE']
    if (file = ENV['FILE'])
      cmd = "mysql #{opts} < #{file}"
      puts "Restoring #{RAILS_ENV} database from #{file} using:"
    else
      cmd = "mysql #{opts}"
      puts "Restoring #{RAILS_ENV} database from STDIN using:"
    end
    puts cmd
    result = system(cmd)
    raise("mysql failed.  msg: #{$?}") unless result
  end
end

def retrieve_db_info
  # read the remote database file....
  # there must be a better way to do this...
  result = File.read "#{RAILS_ROOT}/config/database.yml"
  result.strip!
  config_file = YAML::load(ERB.new(result).result)
  str = %Q['-u#{config_file[RAILS_ENV]["username"]}' ]
  str << %Q['-p#{config_file[RAILS_ENV]["password"]}' ] if
    config_file[RAILS_ENV]['password']
  str << config_file[RAILS_ENV]['database']
  str
end
