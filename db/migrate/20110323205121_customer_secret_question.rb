class CustomerSecretQuestion < ActiveRecord::Migration
  def self.up
    add_column :customers, :secret_question, :integer, :null => false, :default => 0
    add_column :customers, :secret_answer, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :customers, :secret_question
    remove_column :customers, :secret_answer
  end
end
