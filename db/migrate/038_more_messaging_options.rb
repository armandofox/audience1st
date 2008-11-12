module AddOptionHelper

  def add_new_option(id,grp,name,value,description,typ)
    newopt = Option.create!(:grp => grp, :name => name, :value => value.to_s,
                           :description => description, :typ => typ)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=#{id} WHERE id=#{newopt.id}")
  end
  module_function :add_new_option
end

class MoreMessagingOptions < ActiveRecord::Migration
  include AddOptionHelper
  def self.up
    grp = 'Web Site Messaging'
    AddOptionHelper.add_new_option(3016, grp, 'single_ticket_purchase_message', '',
                   'Message that appears for all purchasers on the Buy Tickets page, but NOT on the Buy Subscriptions page.',
                   :text)
    AddOptionHelper.add_new_option(3017, grp, 'subscription_purchase_message',
                   '<span style="color: red; font-weight: bold; size: larger">Is this order a gift?</span> You can enter the recipient\'s name and contact information at the next step.',
                                   'Message that appears for all purchasers on the Buy Subscriptions page, but NOT on the Buy Tickets page',
                                   :text)
  end

  def self.down
  end
end
