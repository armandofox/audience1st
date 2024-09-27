class AddUpdatedAtToVouchertypes < ActiveRecord::Migration[5.0]
  def change
    add_column :vouchertypes, :updated_at, :datetime
  end
end
