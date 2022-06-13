class RemovePromoCodeLengthLimit < ActiveRecord::Migration
  def change
    change_column :valid_vouchers, :promo_code, :string, :limit => 1023
  end
end
