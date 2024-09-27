Purchasemethod = Struct.new(:description, :shortdesc, :nonrevenue, :purchase_medium) do

  def self.get(indx)
    Purchasemethod::ALL[indx]
  end
  def self.valid_purchasemethod?(indx)
    indx.to_i.between?(1,10)  &&  indx.to_i != 3
  end
  def self.must_be_nonzero_amount(indx)
    ! ([2,4,6,7,8].include?(indx))
  end
  def refundable?
    [:web_cc,:box_cash,:box_chk,:none].include?(shortdesc)
  end
  def self.walkup_purchasemethods
    [2,4,5]
  end
  def self.order_reporting_purchasemethods
    [1,4,5]
  end
  def self.get_type_by_name(str)
    Purchasemethod::ALL.index { |p| p.shortdesc.to_s == str.to_s } ||
      4
  end
  def self.default
    4
  end

end

# NOTE: numeric indices matter
Purchasemethod::ALL ||= [
  Purchasemethod.new('INVALID/DUMMY',            :invalid, true,  :none).freeze,          
  Purchasemethod.new('Web - Credit Card',        :web_cc,  false, :credit_card).freeze,   # 1
  Purchasemethod.new('No payment required',      :none,    true,  :cash).freeze,          # 2
  Purchasemethod.new('INVALID/DUMMY',            :invalid, true,  :none).freeze,  # 3 - was box_cc
  Purchasemethod.new('Box office - Cash',        :box_cash,false, :cash).freeze,   # 4
  Purchasemethod.new('Box office - Check',       :box_chk, false, :check).freeze,   # 5
  Purchasemethod.new('Payment Due',              :pmt_due, false, :none).freeze,          # 6
  Purchasemethod.new('External Vendor',          :ext,     false, :third_party).freeze,   # 7
  Purchasemethod.new('Part of a package',	 :bundle,  true,  :none).freeze,          # 8
  Purchasemethod.new('Other',                    :'?purch?',false,:other).freeze,          # 9
  Purchasemethod.new('In-Kind Goods or Services',:in_kind, true,  :none).freeze,          # 10
].freeze


