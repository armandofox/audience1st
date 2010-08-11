class CreateBulkDownload < ActiveRecord::Migration
  def self.up
    create_table :bulk_downloads, :force => true do |t|
      t.string :vendor, :null => true, :default => nil
      t.string :username, :null => true, :default => nil
      t.string :password, :null => true, :default => nil
      t.string :type
      t.text   :report_names
    end
  end

  def self.down
    drop_table :bulk_downloads
  end
end
