require 'rubygems'
#require_gem 'activesupport'
#Gem::require 'activesupport'

class VoucherFixes < ActiveRecord::Migration
  
  def self.up
    now = Time.now
    end_of_this_year = (now + 1.year).at_beginning_of_year
    beginning_of_this_year = now.at_beginning_of_year
    add_column :vouchertypes, :valid_date, :datetime, :null => false, :default => beginning_of_this_year
    remove_column :vouchers, :expiration_date
    add_column :vouchertypes, :expiration_date, :datetime, :null => false, :default => end_of_this_year
    add_column :vouchertypes, :fulfillment_needed, :boolean, :default => false
    # make sure all of THIS YEAR's vouchers and vouchertypes expire 12/31/07
    dec_2007 = (end_of_this_year - 5.days).to_s(:db)
    dec_2008 = (end_of_this_year - 5.days + 1.year).to_s(:db)
    Vouchertype.update_all("expiration_date = '#{dec_2007}'", "id < 50")
    Vouchertype.update_all("expiration_date = '#{dec_2008}'", "id > 49 AND is_bundle = 0")
  end

  def self.down
    remove_column :vouchertypes, :expiration_date
    remove_column :vouchertypes, :valid_date
    remove_column :vouchertypes, :fulfillment_needed
    add_column :voucher, :expiration_date, :date, :null => true, :default => nil
  end
end
