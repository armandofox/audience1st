class ImportCompletedFields < ActiveRecord::Migration
  def self.up
    add_column :imports, :completed_by_id, :integer, :null => true, :default => nil
    add_column :imports, :completed_at, :datetime, :null => true, :default => nil
    Import.update_all("completed_at = '#{Time.now.to_formatted_s(:db)}'", "completed_at IS NULL")
    Import.update_all("completed_by_id = #{Customer.find_by_role(100).id}", "completed_by_id IS NULL")
    remove_column :imports, :completed
  end

  def self.down
    add_column :imports, :completed, :boolean, :null => true, :default => nil
    remove_column :imports, :completed_by_id
    remove_column :imports, :completed_at
  end
end
