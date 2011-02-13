Given /^a "(.*)" vouchertype costing \$?(.*) for the (.*) season$/i do |name,price,season|
  @vouchertype = BasicModels.create_revenue_vouchertype(
    :name => name,
    :price => price,
    :season => season,
    :offer_public => Vouchertype::ANYONE)
end

Then /a vouchertype with name "(.*)" should exist/i do |name|
  @vouchertype = Vouchertype.find_by_name(name)
  @vouchertype.should be_a_kind_of(Vouchertype)
end

Then /it should have a (.*) of (.*)/i do |attr,val|
  if val =~ /"(.*)"/
    @vouchertype.send(attr.downcase).to_s.should == val.to_s
  else
    @vouchertype.send(attr.downcase).should == val.to_i
  end
end

Then /it should be a (.*) voucher/i do |typ|
  @vouchertype.category.should == typ.downcase.to_sym
end

  
