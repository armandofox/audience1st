# to do:
#  add logic to init new donation with correct default account_code (from options)

class Donation < Item

  def self.default_code
    AccountCode.find(Option.default_donation_account_code)
  end
  
  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id
  
  belongs_to :customer
  
  validates_numericality_of :amount
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"

  def self.from_amount_and_account_code_id(amount, id, comments = nil)
    if id.blank? || (use_code = AccountCode.find_by_id(id)).nil?
      use_code = Donation.default_code
    end
    Donation.new(:amount => amount.to_f, :account_code => use_code, :comments => comments)
  end

  def self.to_csv
    CSV.generate(:headers => true) do |csv|
      csv << %w(order_number last first street city state zip email amount date code fund letter_sent letter_sent_by comments)
      all.each do |d|
        csv << [
          d.order.id,
          d.customer.last_name.name_capitalize,
          d.customer.first_name.name_capitalize,
          d.customer.street,
          d.customer.city,
          d.customer.state,
          d.customer.zip,
          d.customer.email,
          d.amount,
          d.sold_on.to_formatted_s(:db),
          d.account_code.code,
          d.account_code.name,
          d.letter_sent,
          (d.letter_sent ? d.processed_by.full_name : ''),
          [d.comments.to_s, d.order.comments.to_s].join('; ')
        ]
      end
    end
  end

  def price ; self.amount ; end # why can't I use alias for this?

  def item_description
    "Donation: #{account_code.name_or_code}"
  end

  def one_line_description(opts={})
    if opts[:suppress_price]
      "Donation to #{account_code.name}"
    else
      sprintf("$%6.2f  Donation to %s", amount, account_code.name)
    end
  end

  def description_for_report ; 'Donation' ; end

  def description_for_audit_txn
    sprintf("%.2f %s donation [%d]", amount, account_code.name, id)
  end

  def self.walkup_donation(amount)
    Donation.new(:amount => amount, :account_code => Donation.default_code)
  end
end
