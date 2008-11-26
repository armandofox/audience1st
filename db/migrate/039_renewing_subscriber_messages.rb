class RenewingSubscriberMessages < ActiveRecord::Migration
  def self.up
    include AddOptionHelper
    grp = 'Web Site Messaging'
    ActiveRecord::Base.connection.execute("DELETE FROM options WHERE id>3015 AND id<3086")
    AddOptionHelper.add_new_option 3050, grp,
    'subscription_sales_banner_for_current_subscribers',
    '<h2 class="subscription_msg">Renew for 2009 Today!</h2> <p class="storeText">See <a href="http://www.altarena.org/2009-season/">five great shows</a> in 2009 and save 20% off the regular ticket price!</p>',
    'Banner text shown on Buy Subscriptions page to patrons who are CURRENT subscribers.  It is placed inside a DIV whose ID and class are subscriptionBannerSubscriber.  The DIV can contain basic HTML tags but no JavaScript.',
    :text
    AddOptionHelper.add_new_option 3054, grp,
    'subscription_sales_banner_for_next_season_subscribers',
    '<h2 class="subscription_msg">Thanks for subscribing to our 2009 season!</h2>',
    'Banner text shown on Buy Subscriptions page to patrons who have purchased subscriptions for next season, whether or not they are current subscribers.  It is placed inside a DIV whose ID and class are subscriptionBannerNextSeasonSubscriber.  The DIV can contain basic HTML tags but no JavaScript.',
    :text
    AddOptionHelper.add_new_option 3056, grp,
    'subscription_sales_banner_for_nonsubscribers',
    '<h2 class="subscription_msg">2009 Season Tickets Now On Sale!</h2> <p class="storeText">See <a href="http://www.altarena.org/2009-season/">five great shows</a> in 2009 and save 20% off the regular ticket price!</p>',
    'Banner text shown on Buy Subscriptions page to NONSUBSCRIBERS.  It is placed inside a DIV whose ID and class are subscriptionBannerNonSubscriber.  The DIV can contain basic HTML tags but no JavaScript.',
    :text
    AddOptionHelper.add_new_option 3060, grp,
    'single_ticket_sales_banner_for_current_subscribers',
    '<h2 class="subscription_msg">2009 Season Tickets: <a href="/store/subscribe">Click Here to Renew &amp; Save</a></h2> <p class="storeText">See <a href="http://www.altarena.org/2009-season/">five great shows</a> in 2009 and save 20% off the regular ticket price!</p>',
    'Banner text shown on Buy Single Tickets page to CURRENT subscribers.  It is placed inside a DIV whose ID and class are storeBannerNonSubscriber.  The DIV can contain basic HTML tags but no JavaScript.',
    :text
    AddOptionHelper.add_new_option 3062, grp,
    'single_ticket_sales_banner_for_next_season_subscribers',
    '<h2 class="subscription_msg">Thanks for Subscribing to our 2009 Season!</h2> <p class="storeText">You\'ll see <a href="http://www.altarena.org/2009-season/">five great shows</a> and get <a href="http://www.altarena.org/2009-season/subscriber-benefits">exclusive subscriber benefits</a>!</p>',
    'Banner text shown on Buy Single Tickets page to patrons who have purchased a subscription for next season, whether or not they are current subscribers. It is placed inside a DIV whose ID and class are storeBannerNextSeasonSubscriber.  The DIV can contain basic HTML tags but no JavaScript.',
    :text
    AddOptionHelper.add_new_option 3064, grp,
    'single_ticket_sales_banner_for_nonsubscribers',
    '<h2 class="subscription_msg">2009 Season Tickets: <a href="/store/subscribe">Click Here to Subscribe &amp;  Save</a></h2> <p class="storeText">See <a href="http://www.altarena.org/2009-season/">five great shows</a> in 2009 and save 20% off the regular ticket price!</p>',
    'Banner text shown on Buy Single Tickets page to NONSUBSCRIBERS.  It is placed inside a DIV whose ID and class are storeBannerNonSubscriber.  The DIV can contain basic HTML tags but no JavaScript.',
    :text
    
  end

  def self.down
  end
end
