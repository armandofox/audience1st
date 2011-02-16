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
      vtypes = params[:seasons].map do |season|
        Vouchertype.subscription_vouchertypes(season)
      end.flatten
    end
    n = LapsedSubscribers.new
    n.generate(:have_vouchertypes => vtypes.map(&:id), :output => self.output_options)
  end
end
      
