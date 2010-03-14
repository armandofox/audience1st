class MoreMessagingCssOptions < ActiveRecord::Migration
  def self.up
    include AddOptionHelper
    AddOptionHelper.add_new_option 3065, 'Web Site Messaging',
    'top_level_banner_text',
    '',
    'Text to be displayed, if any, in top-level header (div#header).',
    :text
  end

  def self.down
  end
end
