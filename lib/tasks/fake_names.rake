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
        :password => 'pass',
        :day_phone => row[4].data)
      i -= 1
      break if i.zero?
    end
  end

end
