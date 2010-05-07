module CustomerHelpers

  $:.push(File.join(RAILS_ROOT, 'spec', 'support'))
  require 'basic_models'
  
  def make_subscriber!(customer)
    vtype = BasicModels.create_subscriber_vouchertype
    voucher = Voucher.new_from_vouchertype(vtype)
    customer.vouchers << voucher
    customer.save!
    customer.should be_a_subscriber
  end

end

World(CustomerHelpers)
  
