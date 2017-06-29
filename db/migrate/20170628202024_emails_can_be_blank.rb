class EmailsCanBeBlank < ActiveRecord::Migration
  def change
    change_column :options, :help_email, :string, :null => true, :default => ''
  end
end
