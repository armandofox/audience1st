class LapsedSubscribers < Report

  def initialize(output_options = {})
    sub_vouchers =  Vouchertype.subscription_vouchertypes
    @view_params = {
      :name => "Lapsed subscribers report",
      :have_vouchertypes => sub_vouchers,
      :dont_have_vouchertypes => sub_vouchers
    }
    super
  end

  def generate(params={})
    have = (params[:have_vouchertypes] ||= []).reject { |x| x.to_i < 1 }
    have_not = (params[:dont_have_vouchertypes] ||= []).reject { |x| x.to_i < 1 }
    unless have.size + have_not.size > 0
      add_error "You  must specify at least one type of voucher from at least one list."
      return nil
    end
    self.output_options = params[:output]
    return Customer.purchased_any_vouchertypes(have) -
      Customer.purchased_no_vouchertypes(have_not)
  end
end
