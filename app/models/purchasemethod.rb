class Purchasemethod < ActiveRecord::Base

  acts_as_reportable

  def purchase_medium
    case self.shortdesc.to_sym
    when :web_cc, :box_cc then :credit_card 
    when :box_cash then :cash 
    when :box_chk then :chk
    else raise "Purchase method '#{self.description}' does not allow accepting payment"
    end
  end

  def self.walkup_purchasemethods
    Purchasemethod.find(:all, :conditions => ["shortdesc LIKE ? AND nonrevenue=?", 'box_%', false]) +
      [Purchasemethod.find_by_shortdesc('none') ]
  end

  def self.get_type_by_name(str)
    Purchasemethod.find_by_shortdesc(str) || Purchasemethod.default
  end
  def self.default
    Purchasemethod.find(:first) ||
      Purchasemethod.create!(:description => 'Other',
      :shortdesc => '?purch?',
      :nonrevenue => false)
  end
end

