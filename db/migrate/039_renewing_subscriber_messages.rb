class RenewingSubscriberMessages < ActiveRecord::Migration
  def self.up
    include AddOptionHelper
    grp = 'Web Site Messaging'
    AddOptionHelper.add_new_option 3052, grp, 'next_season_subscriber_banner',
    '',
    'Banner text shown to patrons who have purchased a subscription for next season, whether or not they are current subscribers.',
    :string
    AddOptionHelper.add_new_option 3054, grp, 'next_season_subscriber_banner_link',
    '',
    "If not blank, link (URL) target of clicking on the next season subscriber banner text.",
    :string
    AddOptionHelper.add_new_option 3072, grp, 'next_season_subscriber_store_message',
    '',
    'When a next-season subscriber visits the ticket-purchase page, this message, if any, will appear right below the "Purchase Individual Tickets" banner. (If the next-season subscriber is also a current subscriber, this message will be shown instead of the current subscriber message.)',
    :text
  end

  def self.down
  end
end
