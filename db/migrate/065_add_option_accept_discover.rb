class AddOptionAcceptDiscover < ActiveRecord::Migration

  include AddOptionHelper
  
  def self.up
    AddOptionHelper.add_new_option 1095, 'Ticket Sales',
    'accept_discover',
    0,
    :int

  end

  def self.down
    ActiveRecord::Base.connection.execute("DELETE FROM options WHERE name='accept_discover'")
  end
end
