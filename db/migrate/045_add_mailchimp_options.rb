module AddOptionHelper

  def add_new_option(id,grp,name,value,description,typ)
    newopt = Option.create!(:grp => grp, :name => name, :value => value.to_s,
                           :description => description, :typ => typ)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=#{id} WHERE id=#{newopt.id}")
  end
  module_function :add_new_option
end

class AddMailchimpOptions < ActiveRecord::Migration
  include AddOptionHelper
  def self.up
    grp = 'External Integration'
    ActiveRecord::Base.connection.execute %Q{UPDATE options SET grp="#{grp}" WHERE grp="External Web Assets"}
    AddOptionHelper.add_new_option 4030, grp,
    'mailchimp_api_key', '',
    'API key for MailChimp integration, if you use MailChimp',
    :string
    AddOptionHelper.add_new_option 4031, grp,
    'mailchimp_username', '',
    'MailChimp user name, if you use MailChimp',
    :string
    AddOptionHelper.add_new_option 4032, grp,
    'mailchimp_password', '',
    'MailChimp password, if you use MailChimp',
    :string
    AddOptionHelper.add_new_option 4033, grp,
    'mailchimp_default_list_name', '',
    'Name of your main email list, if you use MailChimp',
    :string
  end

  def self.down
  end
end
