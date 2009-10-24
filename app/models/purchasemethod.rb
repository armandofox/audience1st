class Purchasemethod < ActiveRecord::Base

  def self.get_type_by_name(str)
    (Purchasemethod.find_by_shortdesc(str) || Purchasemethod.find(:first)).id rescue 0
  end
  def self.default
    Purchasemethod.find(:first)
  end
end

