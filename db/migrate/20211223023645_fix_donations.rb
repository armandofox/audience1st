class FixDonations < ActiveRecord::Migration
  def change
    if AccountCode.default_account_code # to avoid doing it for 'null' (public) tenant schema
      Donation.
        where(:finalized => true).
        where('updated_at >= ?', Time.parse("January 1, 2021")).
        where(:account_code_id => AccountCode.default_account_code_id).
        update_all(:account_code_id => Option.default_donation_account_code)
    end
  end
end
