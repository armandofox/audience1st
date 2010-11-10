require 'add_option_helper'

class AddWelcomeMessage < ActiveRecord::Migration
  def self.up
    AddOptionHelper.add_new_option(3040, "Web Site Messaging", :welcome_page_subscriber_message, '', :text)
    AddOptionHelper.add_new_option(3041, "Web Site Messaging", :welcome_page_nonsubscriber_message, '', :text)
  end

  def self.down
    Option.find(3040).destroy
    Option.find(3041).destroy
  end
end
