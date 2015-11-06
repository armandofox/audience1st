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
    from = Time.from_param(params[:newFrom])
    to = Time.from_param(params[:newTo])
    from,to = to,from if from > to
    result = Customer.donated_during(from, to, amount)
    result |= Customer.subscriber_during(Time.this_season) if params[:include_subscribers]
    result
  end
end
