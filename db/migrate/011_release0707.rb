class TxnType < ActiveRecord::Base ; end
class Release0707 < ActiveRecord::Migration
  def self.up
    add_column :donations, :processed_by, :integer, :null => false, :default => Customer.generic_customer.id
    TxnType.create(:id => 20, :desc => "Acknowledge donation", :shortdesc => "don_ack") unless
      TxnType.find_by_shortdesc("don_ack")
  end

  def self.down
    remove_column :donations, :processed_by
    if (t = TxnType.find_by_shortdesc("don_ack"))
      t.destroy
    end
  end
end
