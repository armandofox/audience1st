

require 'rubygems'
require 'faster_csv'
require_gem 'activerecord'
require File.dirname(__FILE__) + '/../../app/models/donation.rb'
require File.dirname(__FILE__) + '/../../app/models/donation_fund.rb'
require File.dirname(__FILE__) + '/../../app/models/donation_type.rb'
require File.dirname(__FILE__) + '/../../app/models/customer.rb'
require 'pp'

db_config = YAML::load(File.open(File.dirname(__FILE__) + "/../../config/database.yml"))
ActiveRecord::Base.establish_connection(db_config['production'])

exact = 0
inexact = 0
nomatch = 0
FasterCSV.open("more_donations.csv", "w") do |f|
  FasterCSV.foreach("/Users/fox/Documents/fox/projects/vbo/vbo/app/helpers/old_donations.csv", :headers => true) do |r|
    cid = r.field('CustomerID')
    if (c = Customer.find(:first, :conditions => "oldid = #{cid}"))
      exact += 1
      d = Donation.new(:donation_type_id => 1,
                        :amount => r.field('donation').to_f,
                        :date => Date.parse(r.field('orderDt'), :comp => true),
                        :customer_id => c.id,
                       :donation_fund_id => 1)
      d.save!
    elsif ((c = Customer.find(:all, :conditions => ['last_name = ? AND first_name = ?', r.field('LastName'), r.field('FirstName')])).length == 1)
      inexact += 1
      c = c.first
      d = Donation.new(:donation_type_id => 1,
                        :amount => r.field('donation').to_f,
                        :date => Date.parse(r.field('orderDt'), :comp => true),
                        :customer_id => c.id,
                        :donation_fund_id => 1)
      c.oldid = cid
      puts "New date = #{d.date}"
      c.save!
      d.save!
    else
      nomatch += 1
      f << r
    end
  end
end
puts "#{exact} exact matches, #{inexact} inexact, #{nomatch} other, #{exact+inexact+nomatch} total\n"

