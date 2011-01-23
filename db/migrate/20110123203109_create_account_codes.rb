class CreateAccountCodes < ActiveRecord::Migration
  def self.up
    rename_table 'donation_funds', 'account_codes'
    rename_column 'account_codes', 'account_code', 'code'
    default_ac_id = AccountCode.default_account_code_id
    add_column 'vouchertypes', 'account_code_id', :integer,
    :null => false, :default => default_ac_id
    codes = 
      Vouchertype.find_by_sql(
      'select distinct account_code from vouchertypes
        where account_code is not null and account_code != ""').
      map(&:account_code)
    codes.each do |code|
      unless (ac = AccountCode.find_by_code(code))
        ac = AccountCode.create!(:code => code, :name => "Account code #{code}")
      end
      Vouchertype.update_all("account_code_id = #{ac.id}", "account_code = '#{code}'")
    end
    Vouchertype.update_all("account_code_id = #{default_ac_id}",
      "account_code IS NULL or account_code=''")
    remove_column 'vouchertypes', 'account_code'
  end

  def self.down
    add_column 'vouchertypes', 'account_code', :string
    AccountCode.find(:all).each do |ac|
      Vouchertype.update_all("account_code='#{ac.code}'", "account_code_id = #{ac.id}")
    end
    remove_column :vouchertypes, :account_code_id
    rename_table 'account_codes', 'donation_funds'
    rename_column 'donation_funds', 'code', 'account_code'
  end
end
