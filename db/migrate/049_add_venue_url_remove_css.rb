module AddOptionHelper

  def add_new_option(id,grp,name,value,description,typ)
    newopt = Option.create!(:grp => grp, :name => name, :value => value.to_s,
                           :description => description, :typ => typ)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=#{id} WHERE id=#{newopt.id}")
  end
  module_function :add_new_option
end

class AddVenueUrlRemoveCss < ActiveRecord::Migration
  def self.up
    AddOptionHelper.add_new_option 2025, "Contact Information",
    'venue_homepage_url', '', 'URL of venue home page; if provided, page banners will be clickable links to this URL.', :string
  end

  def self.down
  end
end
