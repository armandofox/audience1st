class NonUniqueOrderExternalKey < ActiveRecord::Migration
  def change
    remove_index :orders, :external_key # this index specified unique external_key
    add_index :orders, :external_key    # this one is not
  end
end
