class Store

  module Payment
    
    def self.set_api_key
      Stripe.api_key = Option.stripe_secret
    end

    def self.pay_with_credit_card(order)
      self.set_api_key
      begin
        result = Stripe::Charge.create(
          :amount => (100 * order.total_price).to_i,
          :currency => 'usd',
          :card => order.purchase_args[:credit_card_token],
          :description => order.purchaser.inspect
        )
        order.update_attribute(:authorization, result.id)
      rescue Stripe::StripeError => e
        order.errors.add :base, "Credit card payment error: #{e.message}"
        nil
      end
    end

    def self.refund_credit_card(order, partial_amount=nil)
      self.set_api_key
      amount = ((partial_amount || order.total_price) * 100.0).to_i
      ch = Stripe::Charge.retrieve(order.authorization)
      refund = ch.refunds.create(:amount => amount)
    end
  end

  class Flow
    include Rails.application.routes.url_helpers # for url_for(); :rails5: won't work anymore

    attr_reader :order
    attr_reader :customer       # customer doing the shopping (even if on-behalf'd)
    attr_reader :logged_in      # if non-nil, id of the actually logged in user
    attr_reader :what, :all_shows, :all_showdates, :sh, :sd, :valid_vouchers, :promo_code
    attr_reader :show_url, :showdate_url, :reload_url

    def initialize(current_user, customer, admin_display, params)
      @logged_in = current_user
      @customer = customer
      @admin_display = admin_display
      @params = params

      @sd = @sh = nil
      @valid_vouchers = []
      @all_shows = []
      @all_showdates = []

      @what = Show.type(params[:what])
      @promo_code = params[:promo_code]
    end

    def nothing_to_buy?
      @valid_vouchers.empty? && # no tickets for this showdate
      @all_shows.size == 1   && # no other shows coming up
      @all_showdates.empty?     # no other eligible showdates for this show
    end

    def setup
      return unless (sd = showdate_from_params || showdate_from_show_params || showdate_from_default)
      @what = sd.show.event_type
      @sd = sd
      @sh = @sd.show
      if @admin_display
        @all_showdates = @sh.showdates
        setup_ticket_menus_for_admin
      else
        @all_showdates = @sh.upcoming_showdates
        setup_ticket_menus_for_patron
      end
    end

    private

    def setup_ticket_menus_for_admin
      @valid_vouchers =
        @sd.valid_vouchers.includes(:vouchertype).to_a.
          delete_if(&:subscriber_voucher?).
          map do |v|
        v.customer = @customer
        v.adjust_for_customer
      end.sort_by(&:display_order)
      # remove any comps, EXCEPT those that are "self service with promo code"
      @valid_vouchers = @valid_vouchers.reject do |vv|
        vv.comp? && vv.promo_code.blank?
      end
      @all_shows = Show.for_seasons(Time.this_season - 1, Time.this_season + 1).of_type(@what)  ||  []
      # ensure default show is included in list of shows
      if (@what == 'Regular Show' && !@all_shows.include?(@sh))
        @all_shows << @sh
      end
    end

    def setup_ticket_menus_for_patron
      @valid_vouchers = @sd.valid_vouchers.includes(:vouchertype).map do |v|
        v.customer = @customer
        v.supplied_promo_code = @promo_code
        v.adjust_for_customer
      end.find_all(&:visible?).sort_by(&:display_order)
      
      @all_shows = Show.current_and_future.where('listing_date <= ?', Time.current.to_date).
                     of_type(@what) || []
    end

    def showdate_from_params
      Showdate.includes(:valid_vouchers).find_by_id(@params[:showdate_id])
    end
    def showdate_from_show_params
      (s = Show.find_by_id(@params[:show_id])) &&
        (s.upcoming_showdates.first || s.showdates.first)
    end
    def showdate_from_default ; Showdate.current_or_next(:type => @params[:what]) ; end


  end

end

