Given /^the following account codes exist:$/ do |tbl|
  tbl.hashes.each do |acc_code|
    ac = create(:account_code, :code => acc_code["code"], :name => acc_code["name"])
    used_for = acc_code["used_for"]
    case used_for
    when /donations/i
      Option.first.update_attributes!(:default_donation_account_code => ac.id)
    else
      used_for.split(/\s*,\s*/).each do |vtype_name|
        Vouchertype.find_by!(:name => vtype_name).update_attributes!(:account_code => ac)
      end
    end
  end
end

  
