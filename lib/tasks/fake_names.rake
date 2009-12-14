namespace :db do
  desc "Given ENV[FILE] is a CSV with columns <last, first, street, phone, email>, repopulates development DB with fake data."
  task :fake_names => :environment do
    abort "Only works for RAILS_ENV=development" unless ENV['RAILS_ENV']=='development'
    require 'string_extras'
    require 'generator'
    require 'csv'
    csv = CSV::Reader.create(File.open(ENV['FILE'], 'r'))
    custs = Customer.find(:all)
    SyncEnumerator.new(custs, csv).each do |customer,row|
      break unless customer
      unless customer.role == 100 # skip admins
        customer.update_attribute(:first_name, row[0].data)
        customer.update_attribute(:last_name, row[1].data)
        customer.update_attribute(:street, row[2].data) unless
          customer.street.blank?
        customer.update_attribute(:day_phone,row[4].data) unless
          customer.day_phone.blank?
        customer.update_attribute(:eve_phone, '')
        unless customer.email.blank?
          customer.update_attribute(:email, row[3].data)
          customer.update_attribute(:login, row[3].data)
          customer.update_attribute(:password, row[5].data)
        end
      end
    end
  end

  desc "Given ENV[FILE] is a CSV with columns <last, first, street, phone, email>, creates ENV[NUM] fake customers in the database."
  task :populate_fake_names => :environment do
    require 'string_extras'
    require 'generator'
    require 'csv'
    i = ENV['NUM'].to_i
    CSV::Reader.parse(File.open(ENV['FILE'], 'r')) do |row|
      Customer.create!(:first_name => row[0].data,
        :last_name => row[1].data,
        :street => row[2].data,
        :city => 'Berkeley',
        :state => 'CA',
        :zip => '94720',
        :email => row[3].data,
        :login => row[3].data,
        :password => 'pass',
        :day_phone => row[4].data)
      i -= 1
      break if i.zero?
    end
  end

end

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
