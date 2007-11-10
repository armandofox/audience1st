require 'rubygems'
require_gem 'activerecord'
require File.dirname(__FILE__) + '/../../app/models/donation.rb'
require File.dirname(__FILE__) + '/../../app/models/donation_fund.rb'
require File.dirname(__FILE__) + '/../../app/models/donation_type.rb'
require File.dirname(__FILE__) + '/../../app/models/customer.rb'

db_config = YAML::load(File.open(File.dirname(__FILE__) + "/../../config/database.yml"))
ActiveRecord::Base.establish_connection(db_config['production'])

i=0
Donation.find(:all, :conditions => 'date < "2003-12-12"').each do |d|
  old = d.date.to_s
  #printf( "#{old} --> ")
  old[0] = '2'
  d.date = Date.strptime(old)
  #puts "#{d.date}\n"
  d.save!
  i+=1
end
puts "Fixed #{i} record\n"
