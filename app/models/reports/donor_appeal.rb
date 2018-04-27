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
    @relation = Customer.donated_during(from, to, amount)
  end
end
