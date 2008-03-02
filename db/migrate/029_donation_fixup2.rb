class DonationFixup2 < ActiveRecord::Migration

  # desired schema:
  #  each donation has a donation fund (def=General), acct code
  #  (def=whatever is defined in Options), and purchasemethod. 

  def self.up
    # add account code to donation
    add_column :donations, :account_code, :string,:null =>true, :default=>nil
    #   - foreach donation, set account code to the account code currently
    #     associated with its donation_type
    update_donations = <<EOQ1
      UPDATE donations d,donation_types dt 
        SET d.account_code=dt.account_code 
        WHERE d.donation_type_id=dt.id
EOQ1
    ActiveRecord::Base.connection.execute(update_donations)
    # Don't need donation_types or its association anymore
    remove_column :donations,:donation_type_id
    drop_table :donation_types
    # Finally, create a "default Account Code  for donations" config option
    o = Option.create!(:grp => "Ticket Sales",
                       :name => "default_donation_account_code",
                       :value => "",
                       :typ => :string,
                       :description => "Default account code applied to donations made online. If empty, no account code will be assigned to those donations.")
    # ...and set its ID properly
    cmd = "UPDATE options SET id=1060 WHERE id=#{o.id}"
    ActiveRecord::Base.connection.execute(cmd)

  end

  def self.down
  end
end
