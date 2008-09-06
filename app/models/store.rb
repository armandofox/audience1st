class Store

  def self.options_for_credit_card
    opts = [['Visa', 'visa'], ['MasterCard','master'], ['Discover','discover'],
            ['Diners Club','diners_club']]
    opts << ['AmEx', 'american_express'] unless Option.value(:accept_amex).blank?
    opts
  end

end
