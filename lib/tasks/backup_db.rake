namespace :db do

  def do_db_cmd(cmd,archive=nil)
    archive ||= ENV['FILE'] || Time.now.strftime("%Y%m%d-%H%M%S.sql")
    cmd << " > #{archive}"
    puts "With Rails.env=#{Rails.env}, running '#{cmd}'"
    result = system(cmd)
    raise("FAILED: #{$?}") unless result
  end

  desc "Dump DB corresponding to ENV[RAILS_ENV] to ENV[FILE] or an auto-generated filename"
  task :dump_sql => :environment do
    do_db_cmd("mysqldump --add-drop-database --opt --skip-add-locks #{retrieve_db_info}")
  end

  desc "Restore DB corresponding to ENV[RAILS_ENV] from ENV[FILE] or STDIN"
  task :restore_sql => :environment do
    opts = retrieve_db_info
    #raise "Must set FILE=filename to restore from" unless file = ENV['FILE']
    if (file = ENV['FILE'])
      cmd = "mysql #{opts} < #{file}"
      puts "Restoring #{Rails.env} database from #{file} using:"
    else
      cmd = "mysql #{opts}"
      puts "Restoring #{Rails.env} database from STDIN using:"
    end
    puts cmd
    result = system(cmd)
    raise("mysql failed.  msg: #{$?}") unless result
  end

  desc "Import MySQL dump ENV['FILE'] to Postgres tenant schema ENV['SCHEMA']"
  task :import_pg => :environment do
    file = ENV['FILE']
    abort "File '#{ENV["FILE"]}' doesn't exist (set ENV['FILE'])" if file.blank?
    schema = ENV['SCHEMA']
    abort "Schema cannot be blank" if schema.blank?
    user,pass,db = get_user_pass_db
    File.open("#{file}.pg","w") do |f|
      f.puts "BEGIN;\nSET LOCAL search_path = #{schema};\n"
    end
    abort "Cannot cat #{file}" unless system("cat #{file} >> #{file}.pg")
    File.open("#{file}.pg","a") do |f|
      f.puts "COMMIT;\n"
    end
    abort "Import error" unless system("PGPASSWORD=#{pass} psql '-U#{user}' -d #{db} < #{file}.pg")
  end
end

def get_user_pass_db
  # read the remote database file....
  # there must be a better way to do this...
  result = File.read "#{Rails.root}/config/database.yml"
  result.strip!
  config_file = YAML::load(ERB.new(result).result)
  user = config_file[Rails.env]['username']
  pass = config_file[Rails.env]['password']
  db = config_file[Rails.env]['database']
  return [user,pass,db]
end

def retrieve_db_info
  user,pass,db = get_user_pass_db
  "'-u#{user}' '-p#{pass}' #{db}"
end
