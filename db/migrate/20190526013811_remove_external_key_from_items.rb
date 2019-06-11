class RemoveExternalKeyFromItems < ActiveRecord::Migration
  def change
    Item.transaction do
      Item.where("external_key IS NOT NULL AND external_key != '' AND external_key != '0'").each do |i|
        i.order.update_attributes!(:external_key => i.external_key)
      end
    end
    remove_column :items, :external_key
  end
end
