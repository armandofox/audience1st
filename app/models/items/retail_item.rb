class RetailItem < Item

  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id
  validates_presence_of :comments, :message => "or description can't be blank"

  validates_numericality_of :amount, :greater_than => 0.0

  def price ; amount ; end

  def item_description
    "Retail: #{comments}"
  end

  def self.new_service_charge_for(what='Regular Show')
    if (what == 'Class' && (amount = Option.classes_order_service_charge) > 0)
      new(:amount => amount,
        :comments => Option.classes_order_service_charge_description,
        :account_code => AccountCode.find(Option.classes_order_service_charge_account_code))
    elsif (what == 'Subscription' && (amount = Option.subscription_order_service_charge) > 0)
      new(:amount => amount,
        :comments => Option.subscription_order_service_charge_description,
        :account_code => AccountCode.find(Option.subscription_order_service_charge_account_code))
    elsif (amount = Option.regular_order_service_charge) > 0
      new(:amount => amount,
        :comments => Option.regular_order_service_charge_description,
        :account_code => AccountCode.find(Option.regular_order_service_charge_account_code))
    else
      nil
    end
  end

  def self.default_code
    AccountCode.find(Option.default_retail_account_code)
  end

  def self.from_vouchertype(vt)
    item = RetailItem.new(:vouchertype => vt, :amount => vt.price, :account_code => vt.account_code, :comments => vt.name)
  end
  
  def self.from_amount_description_and_account_code_id(amount, description, id=nil)
    item = RetailItem.new(:amount => amount, :comments => description,
      :account_code => (AccountCode.find_by_id(id) || RetailItem.default_code))
  end

  def one_line_description(suppress_price: false)
    if suppress_price
      comments
    else
      sprintf("$%6.2f  #{comments}", amount)
    end
  end

  def description_for_report ; comments.to_s.gsub("\n", "; ") ; end

  def description_for_audit_txn
    sprintf("%.2f #{comments} [#{id}]", amount)

  end

end
