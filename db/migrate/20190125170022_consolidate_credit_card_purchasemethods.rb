class ConsolidateCreditCardPurchasemethods < ActiveRecord::Migration
  def change
    # 3 is "box office - credit card", 1 is "web - credit card" in orig schema
    Order.where(:purchasemethod => 3).update_all(:purchasemethod => 1)
    Txn.where(:purchasemethod => 3).update_all(:purchasemethod => 1)
  end
end
