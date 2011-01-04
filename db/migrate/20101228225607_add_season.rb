class AddSeason < ActiveRecord::Migration
  def self.up
    add_column :vouchertypes, :season, :integer, :limit => 4, :null => false, :default => 2011
    Vouchertype.find(:all).each do |v|
      if (name =~ /20??/)
        season = Regexp.last_match(0)
      elsif v.expiration_date.year <= 2011
        season = v.expiration_date.year
      elsif v.created_on.year <= 2011
        season = v.created_on.year
      else
        season = 2011
      end
      v.update_attribute(:season, season)
    end
    rename_column :vouchertypes, :created_on, :created_at
  end

  def self.down
    remove_column :vouchertypes, :season
    rename_column :vouchertypes, :created_at, :created_on
  end
end
