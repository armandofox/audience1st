class AddBccToOptions < ActiveRecord::Migration
  def change
    add_column :options, :transactional_bcc_email, :string, :null => true, :default => nil
  end
end
