class DonorAppeal < Report

  def initialize(options={})
    @view_params = {
      :name => "Donor appeal"
    }
    super
  end

  def generate(params={})
    # if subscribers included, need to join to vouchertypes table
    amount = params[:donation_amount].to_f
    from,to = Time.range_from_params(params[:special_report_dates])
    result = Customer.donated_during(from, to, amount)
    result |= Customer.subscriber_during(Time.this_season) if params[:include_subscribers]
    @relation = result
  end
end
