class SubscriptionSalesReport
  attr_reader :vouchers_for_display, :csv
  
  def initialize(season)
    @season = season
    @csv = nil
    @vouchers_for_display = []
  end

  # count the number of subscriptions for a given season
  def run
    season_start = Time.current.at_beginning_of_season(@season)
    v = Vouchertype.subscription_vouchertypes(@season)
    @vouchers_for_display = v.map { |t| [t.name, t.price.round, Voucher.where(:finalized => true, :vouchertype_id => t.id).count] }
    @csv = CSV.generate do |csv|
      csv << %w[name amount quantity]
      q=0 ; t=0
      @vouchers_for_display.each { |s| csv << s ; t += s[1]*s[2] ; q += s[2] }
      csv << ['Total',t,q]
    end
    self
  end

end
