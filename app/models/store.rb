class Store

  def self.options_for_credit_card
    opts = [['Visa', 'visa'], ['MasterCard','master'], ['Discover','discover'],
            ['Diners Club','diners_club']]
    ((amx = Option.value(:accept_amex)).blank? || amx.zero?) ? opts :
      opts << ['AmEx', 'american_express']
  end

end
