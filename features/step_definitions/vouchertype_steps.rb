Then /a vouchertype with name "(.*)" should exist/i do |name|
  @it = Vouchertype.find_by_name(name)
  @it.should be_a_kind_of(Vouchertype)
end

Then /it should have a (.*) of (.*)/i do |attr,val|
  if val =~ /"(.*)"/
    @it.send(attr.downcase).to_s.should == val.to_s
  else
    @it.send(attr.downcase).should == val.to_i
  end
end

Then /it should be a (.*) voucher/i do |typ|
  @it.category.should == typ.downcase.to_sym
end

  
