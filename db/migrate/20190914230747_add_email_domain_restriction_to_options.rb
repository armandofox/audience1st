class AddEmailDomainRestrictionToOptions < ActiveRecord::Migration
  def change
    change_table :options do |t|
      t.string :restrict_customer_email_to_domain, :null => true, :default => nil
    end
  end
end
