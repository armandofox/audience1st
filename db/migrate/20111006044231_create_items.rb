class CreateItems < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :date, :datetime
    add_column :vouchers, :amount, :float
    add_column :vouchers, :account_code_id, :integer
    add_column :vouchers, :comment, :string
    add_column :vouchers, :created_at, :datetime
    add_column :vouchers, :updated_at, :datetime
    add_column :vouchers, :letter_sent, :datetime

    add_column :vouchers, :type, :string
    Voucher.update_all("type = 'Voucher'")

    count = Donation.count
    Donation.all.each do |d|
      Voucher.create!(
        :type => 'Donation',
        :date => d.date,
        :amount => d.amount,
        :account_code_id => d.account_code_id,
        :comment => d.comment,
        :customer_id => d.customer_id,
        :created_at => d.created_at,
        :updated_at => d.updated_at,
        :letter_sent => d.letter_sent,
        :processed_by_id => d.processed_by_id,
        :purchasemethod_id => d.purchasemethod_id
        )
    puts "#{d.id} / #{count}" if d.id % 100 == 0
    end
    rename_table :vouchers, :items
    drop_table :donations
  end

  def self.down
    create_table "donations", :force => true do |t|
      t.datetime "date"
      t.float    "amount",            :default => 0.0,        :null => false
      t.integer  "account_code_id",   :default => 0,          :null => false
      t.string   "comment"
      t.integer  "customer_id",       :default => 0,          :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "letter_sent"
      t.integer  "processed_by_id",   :default => 2146722771, :null => false
      t.integer  "purchasemethod_id", :default => 1,          :null => false
    end
    puts "Extracting #{Item.count(:conditions => ['type = ?', 'Donation'])} donations"
    Item.find_all_by_type('Donation').each do |d|
      Donation.create!(
        :date => d.date,
        :amount => d.amount,
        :account_code_id => d.account_code_id,
        :comment => d.comment,
        :customer_id => d.customer_id,
        :created_at => d.created_at,
        :updated_at => d.updated_at,
        :letter_sent => d.letter_sent,
        :processed_by_id => d.processed_by_id,
        :purchasemethod_id => d.purchasemethod_id
        )
    end
    remove_column :items, :type
    rename_table :items, :vouchers
  end
end
