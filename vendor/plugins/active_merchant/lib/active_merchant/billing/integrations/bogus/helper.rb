module ActiveMerchant
  module Billing
    module Integrations
      module Bogus
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          mapping :account, 'account'
          mapping :order, 'order'
          mapping :amount, 'amount'
          mapping :currency, 'currency'
          mapping :customer, :first_name => 'first_name',
                             :last_name => 'last_name'

        end
      end
    end
  end
end
