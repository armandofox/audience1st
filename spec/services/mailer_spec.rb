require 'rails_helper'

describe Mailer, :type => :mailer do

  describe 'previewing' do
    specify 'order confirmation' do
      order = create(:order, :vouchers_count => 2, :contains_donation => true)
      email = Mailer.confirm_order(order.purchaser, order)
    end
  end
      
end
