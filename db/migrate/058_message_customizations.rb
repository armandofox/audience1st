class MessageCustomizations < ActiveRecord::Migration
  include Enumerable
  @opts = [
    :homepage_ticket_sales_text,
    'Homepage message that will take customer to Buy Tickets page; if blank, link to Tickets page won\'t be displayed',
    'Buy Tickets',
    :string,
    
    :homepage_subscription_sales_text,
    'Homepage message that will take customer to Buy Subscriptions page; if blank, link to Subscriptions page won\'t be displayed',
    'Subscribe Now!',
    :text,
    
    :subscription_purchase_email_notes,
    'Additional text included in purchase confirmation screen and email when a new or renewal subscription is PURCHASED.  Can include basic HTML tags and CSS information. It is automatically rendered inside <div id="subscription_purchase_notices"> and converted to plain text for confirmation email.',
    '',
    :text,

    :display_email_opt_out,
    'If set to any nonzero value, an email opt-out box will appear whenever customers edit their contact info.  If set to zero, this opt-out box will not appear.  NOTE: if set to zero, you MUST ensure that you provide your customers some other way to opt out of email in order to comply with CAN-SPAM.',
    0,
    :integer,
    
    :encourage_email_opt_in,
    'Brief message encouraging customers who have opted out of email to opt back in.  Use plain text only.  If present, will be displayed along with a link to an opt-back-in page for customers who have a valid email address on file but have opted out.  If blank, or if customer has no email address on file, no message or link will be displayed.',
    'We miss having you on our email list!',
    :string
  ]

  def self.up

    id = 3070
    @opts.each_slice(4) do |opt|
      name, description, value, typ = opt
      newopt = Option.create!(:grp => 'Web Site Messaging',
        :name => name.to_s,
        :value => value.to_s,
        :description => description,
        :typ => typ)
      ActiveRecord::Base.connection.execute("UPDATE options SET id=#{id} WHERE id=#{newopt.id}")
      id += 1
    end

    newopt = Option.create!(
      :grp => 'External Integration',
      :name => 'enable_facebook_connect',
      :value => '1',
      :description => 'Set to zero (0) to COMPLETELY DISABLE Facebook integration, including "Login with your Facebook account" and Facebook-related social features.  Set to any nonzero value to ENABLE Facebook integration.  NOTE:  This change may take up to an hour to take effect.',
      :typ => :integer)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=4070 WHERE id=#{newopt.id}")
  end

  def self.down
    @opts.each_slice(4) do |opt|
      Option.find_by_name(opt[0]).destroy
    end
    Option.find_by_name(:enable_facebook_connect).destroy
  end
end
