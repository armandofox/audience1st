class AddSeason < ActiveRecord::Migration
  def self.up
    add_column :vouchertypes, :season, :integer, :limit => 4, :null => true, :default => nil
    Vouchertype.find(:all).each do |v|
      if (name =~ /20??/)
        season = Regexp.last_match(0)
      elsif v.expiration_date.year <= 2011
        season = v.expiration_date.year
      elsif v.sold_on.year <= 2011
        season = v.sold_on.year
      else
        season = 2011
      end
      v.update_attribute(:season, season)
    end
    remove_column :vouchertypes, :expiration_date
    rename_column :vouchertypes, :created_on, :created_at
  end

  def self.down
    add_column :vouchertypes, :expiration_date, :datetime, :null => true, :default => nil
    Vouchertype.find(:all).each do |v|
      v.update_attribute(:expiration_date, Date.civil(v.season, 12, 31))
    end
    remove_column :vouchertypes, :season
    rename_column :vouchertypes, :created_at, :created_on
  end
end
