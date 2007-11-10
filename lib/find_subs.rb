class SubFinder

  def self.find_subs
    sub2007 = (21..26).to_a + (29..32).to_a
    sub2008 = (55..58).to_a

    c = Customer.find_by_sql("SELECT c.* FROM customers c,vouchers v WHERE c.id=v.customer_id AND ((v.vouchertype_id >= 21 AND v.vouchertype_id <= 26) OR (v.vouchertype_id >= 29 AND v.vouchertype_id <= 32))")

    c.reject! { |cu| cu.vouchers.any? { |v| sub2008.include?(v) } }

    out = File.open('/tmp/csvout','wb') do
      CSV::Writer.generate(out) do |csv|
        c.each do |cu|
          csv << [cu.first_name, cu.last_name, cu.street, cu.city, cu.state, cu.zip]
        end
      end
    end
  end    
end
