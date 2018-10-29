class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :current_season => Time.this_season
    }
    super
  end

  def generate(params = {})
    seasons = params[:seasons]
    @relation = 
      if seasons.empty?
      then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
      else Customer.subscriber_during seasons.first.split(',')
      end
  end
end

