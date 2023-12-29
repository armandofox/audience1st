class SetZeroPriceBundlesToBoxofficeOnly < ActiveRecord::Migration
  def change
    Vouchertype.where(:category => 'bundle').where(:price => 0).
      update_all(:offer_public => Vouchertype::BOXOFFICE)
  end
end
