class RemoveOfferPublicExternal < ActiveRecord::Migration
  def change
    Vouchertype.where(:offer_public => -1).update_all(:offer_public => 0)
  end
end
