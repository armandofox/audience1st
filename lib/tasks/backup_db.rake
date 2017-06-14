namespace :db do

  def do_db_cmd(cmd,archive=nil)
    archive ||= ENV['FILE'] || Time.now.strftime("%Y%m%d-%H%M%S.sql")
    cmd << " > #{archive}"
    puts "With RAILS_ENV=#{RAILS_ENV}, running '#{cmd}'"
    result = system(cmd)
    raise("FAILED: #{$?}") unless result
  end

  desc "Dump DB corresponding to RAILS_ENV to ENV[FILE] or an auto-generated filename"
  task :dump_sql => :environment do
    do_db_cmd("mysqldump --add-drop-database --opt --skip-add-locks #{retrieve_db_info}")
  end

  desc "Restore DB corresponding to RAILS_ENV from ENV[FILE] or STDIN"
  task :restore_sql => :environment do
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
  result = File.read "#{Rails.root}/config/database.yml"
  result.strip!
  config_file = YAML::load(ERB.new(result).result)
  str = %Q['-u#{config_file[RAILS_ENV]["username"]}' ]
  str << %Q['-p#{config_file[RAILS_ENV]["password"]}' ] if
    config_file[RAILS_ENV]['password']
  str << config_file[RAILS_ENV]['database']
  str
end
