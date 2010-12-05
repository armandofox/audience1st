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

  def find_customer_by_fullname(name)
    c = Customer.find_by_first_name_and_last_name(*(name.split(/ +/))) or raise ActiveRecord::RecordNotFound
  end
end

World(CustomerHelpers)
  
