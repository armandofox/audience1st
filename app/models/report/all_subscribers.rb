class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :current_season => Time.this_season
    }
    super
  end

  def generate(params = {})
    if (seasons = params[:seasons]).empty?
      vtypes = Vouchertype.subscription_vouchertypes
    else
      vtypes = params[:seasons].first.split(',').map do |season|
        Vouchertype.subscription_vouchertypes(season.to_i)
      end.flatten
    end
    Customer.purchased_any_vouchertypes(vtypes.map(&:id))
  end
end
      
