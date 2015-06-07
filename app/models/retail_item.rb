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

  def self.foreign_keys_to_customer
    [:customer_id, :processed_by_id]
  end

  def self.default_code
    AccountCode.find(Option.default_retail_account_code)
  end

  def self.from_amount_description_and_account_code_id(amount, description, id)
    if id.blank? || (use_code = AccountCode.find_by_id(id)).nil?
      use_code = RetailItem.default_code
    end
    item = RetailItem.new(:amount => amount, :comments => description, :account_code => use_code)
  end

  def one_line_description
    sprintf("$%6.2f  Purchase: #{comments}", amount)
  end

end
