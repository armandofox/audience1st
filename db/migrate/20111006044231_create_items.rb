class LegacyDonation < ActiveRecord::Base
  set_table_name 'donations'
end
class LegacyVoucher < ActiveRecord::Base
  set_table_name 'vouchers'
end
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
    vcount = LegacyVoucher.count
    dcount = LegacyDonation.count

    begin
      LegacyVoucher.transaction do
        idx = 0
        connection.execute("UPDATE vouchers SET type='Voucher'")
        LegacyDonation.all.each do |d|
          LegacyVoucher.create!(
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
          idx += 1
          puts "#{idx} / #{dcount}" if idx % 100 == 0
        end
        newtotal = LegacyVoucher.count
        raise "Miscount: expected #{dcount+vcount} total, got #{newtotal}" unless dcount+vcount == newtotal
        connection.execute("UPDATE vouchers SET type='Donation' WHERE category IS NULL AND type IS NULL")
        newdonations = LegacyVoucher.count(:conditions => "type='Donation'")
        raise "Miscount: expected #{dcount} donations, got #{newdonations}" unless newdonations == dcount
      end
      rename_table :vouchers, :items
      drop_table :donations
      add_index :items, :type
    rescue Exception => e
      %w(date amount account_code_id comment created_at updated_at letter_sent type).each do |col|
        remove_column :vouchers, col
      end
      raise e
    end
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
    dcount = Donation.count
    vcount = Voucher.count
    puts "Extracting #{dcount} donations"
    begin
      transaction do
        Donation.all.each do |d|
          LegacyDonation.create!(
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
        newdcount = LegacyDonation.count
        raise "Miscount: expected #{dcount} donations, got #{newdcount}" unless newdcount == dcount
        Item.delete_all("type='Donation'")
        newvcount = Voucher.count
        raise "Miscount: expected #{vcount} vouchers, got #{newvcount}" unless newvcount == vcount
        # all is well, finish transaction
      end
      %w(type date amount account_code_id comment created_at updated_at letter_sent).each do |col|
        remove_column :items, col
      end
    rescue Exception => e # something went wrong in transcription
      drop_table :donations
      raise e
    end
    rename_table :items, :vouchers
  end
end
