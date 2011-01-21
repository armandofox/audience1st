class RenumberCustomers

  model :customer
  model :donation
  model :voucher
  model :txn
  model :import
  model :visit

  def run
    new = 0
    cs = Customer.find(:all)
    transaction do
      new += 1
      cs.each do |c|
        old = c.id
        Customer.update_all("referred_by_id = '#{new}'", "referred_by_id = '#{old}'")
        l = Label.rename_customer(old, new)
        [Donation, Voucher, Txn, Visit, Import].each do |t|
          t.foreign_keys_to_customer.each do |field|
            howmany += t.update_all("#{field} = '#{new}'", "#{field} = '#{old}'")
          end
        end
        connection.execute("UPDATE customers SET id=#{new} WHERE id=#{old}")
      end
      connection.execute("ALTER TABLE customers AUTO_INCREMENT=#{new+1}")
    end
  end
end
