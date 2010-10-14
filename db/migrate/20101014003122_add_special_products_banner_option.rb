class AddSpecialProductsBannerOption < ActiveRecord::Migration
  def self.up
    id = 3045
    ['current_subscribers', 'next_season_subscribers', 'nonsubscribers'].each do |m|
      opt = Option.create!(:grp => 'Web Site Messaging',
        :name => "special_event_sales_banner_for_#{m}",
        :typ => :text, :value => '')
      ActiveRecord::Base.connection.execute("UPDATE options SET id=#{id} WHERE id=#{opt.id}")
      id += 1
    end
  end

  def self.down
    [3045,3046,3047].each { |i| Option.delete(i) }
  end
end
