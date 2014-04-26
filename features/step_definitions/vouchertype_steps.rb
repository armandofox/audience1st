Given /^a "(.*)" vouchertype costing \$?(.*) for the (.*) season$/i do |name,price,season|
  @vouchertype = Vouchertype.find_by_name_and_price_and_season(name,price,season) ||
    BasicModels.create_revenue_vouchertype(
    :name => name,
    :price => price,
    :season => season,
    :walkup_sale_allowed => true,
    :category => (price.to_f.zero? ? :comp : :revenue),
    :offer_public => (price.to_f.zero? ? Vouchertype::BOXOFFICE : Vouchertype::ANYONE)
    )
end

Given /^a bundle "(.*)" containing:$/ do |name,tickets|
  bundle = BasicModels.create_bundle_vouchertype(:name => name)
  bundle.included_vouchers = {}
  tickets.hashes.each do |h|
    show_name = h['show']
    the_showdate = Time.parse(h['date'])
    bundle_component = BasicModels.create_included_vouchertype(:name => "#{show_name} (bundle)")
    bundle.included_vouchers[bundle_component.id] = h['qty']
    bundle.season = the_showdate.year
    # make it valid for just the one showdate
    showdate = BasicModels.create_one_showdate(the_showdate, 100, nil, show_name)
    showdate.valid_vouchers.create!(:vouchertype => bundle_component,
      :start_sales => 1.week.ago, :end_sales => 1.week.from_now, :max_sales_for_type => 100)
  end
  bundle.save!
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

  
