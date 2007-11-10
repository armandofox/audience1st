class FixByWhom

  model :customer
  model :voucher
  model :vouchertype
  model :txn

  f = File.new("/tmp/vouchers", "w+")
  generic_id = Customer.generic_customer.id
  conds = ["showdate_id > 0",
           "by_whom != #{generic_id}"].join(" AND ")
  Voucher.find(:all,:conditions => conds).each do |v|
    t = Txn.find(:first,:conditions => "voucher_id = #{v.id}",
                 :order => "txn_date DESC")
    unless (who = t.entered_by_id).zero?
      #v.update_attributes(:by_whom => who)
      puts "#{v.id} => #{Customer.find(who).login}"
    else
      f.puts "#{v.id},#{t.id}"
    end
  end
end
