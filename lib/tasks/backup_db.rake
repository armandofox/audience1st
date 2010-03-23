namespace :db do

  static_tables = "options purchasemethods txn_types schema_migrations"

  def do_db_cmd(cmd,archive=nil)
    archive ||= ENV['FILE'] || Time.now.strftime("%Y%m%d-%H%M%S.sql")
    cmd << " > #{archive}"
    puts "With RAILS_ENV=#{RAILS_ENV}, running '#{cmd}'"
    result = system(cmd)
    raise("FAILED: #{$?}") unless result
  end

  desc "Dump DB corresponding to RAILS_ENV to ENV[FILE] or an auto-generated filename"
  task :dump => :environment do
    do_db_cmd("mysqldump --opt --skip-add-locks #{retrieve_db_info}")
  end

  desc "Dump static tables only (#{static_tables}) ENV[FILE] or auto-generated filename"
  task :dump_static => :environment do
    do_db_cmd("mysqldump --opt --skip-add-locks #{retrieve_db_info} #{static_tables}")
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
