class MoreMessagingCssOptions < ActiveRecord::Migration
  def self.up
    opt = Option.create!(:grp => 'Web Site Messaging',
      :name =>     'top_level_banner_text',
      :description =>     'Text to be displayed, if any, in top-level header (div#header).',
      :value => '',
      :typ => :text)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=3065 WHERE id=#{opt.id}")
  end

  def self.down
  end
end
