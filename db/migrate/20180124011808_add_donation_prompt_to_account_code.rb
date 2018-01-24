class AddDonationPromptToAccountCode < ActiveRecord::Migration
  def self.up
    add_column :account_codes, :donation_prompt, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :account_codes, :donation_prompt
  end
end
