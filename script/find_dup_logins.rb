

require 'rubygems'
require_gem 'activerecord'
require File.dirname(__FILE__) + '/../app/models/customer.rb'
require 'pp'

db_config = YAML::load(File.open(File.dirname(__FILE__) + "/../config/database.yml"))
ActiveRecord::Base.establish_connection(db_config['production'])

match = 0
done = 0
Customer.find(:all, :conditions => "login IS NOT NULL AND login != ''").each do |c|
  done += 1
  unless (done % 100)
    putc "."
  end
  Customer.find(:all, :conditions => "id != #{c.id} AND login = '#{c.login}'").each do |c2|
    puts "id #{c.id},#{c2.id} same login #{c.login}\n"
    match += 1
  end
end
puts "#{match} matches"

