Given /^the display orders of "(.*)" and "(.*)" are set to (\d+) and (\d+)$/ do |v1_name,v2_name,d1,d2|
  Vouchertype.find_by_name!(v1_name).update_attributes!(:display_order => d1)
  Vouchertype.find_by_name!(v2_name).update_attributes!(:display_order => d2)
end

Given /^a "(.*)" vouchertype costing \$?(.*) for the (.*) season$/i do |name,price,season|
  @vouchertype = Vouchertype.find_by_name_and_price_and_season(name,price,season) ||
    Vouchertype.create!(
    :name => name,
    :price => price,
    :season => season,
    :walkup_sale_allowed => true,
    :category => (price.to_f.zero? ? 'comp' : 'revenue'),
    :offer_public => (price.to_f.zero? ? Vouchertype::BOXOFFICE : Vouchertype::ANYONE)
    )
end

When /^I click the delete icon for the "(.*)" vouchertype$/ do |vtype|
  page.find(:css, "img#delete_#{Vouchertype.find_by_name!(vtype).id}").click
end

Given /^a bundle "(.*)" for \$?([0-9.]+) containing:$/ do |name,price,tickets|
  bundle = build(:bundle,:name => name, :price => price.to_f)
  bundle.included_vouchers = {}
  tickets.hashes.each do |h|
    show_name = h['show']
    the_showdate = Time.zone.parse(h['date'])
    bundle_component = create(:vouchertype_included_in_bundle, :season => the_showdate.year, :name => "#{show_name} (bundle)")
    bundle.included_vouchers[bundle_component.id] = h['qty']
    bundle.season = the_showdate.year
    # make it valid for just the one showdate
    showdate = create(:showdate, :date => the_showdate, :max_sales => 100, :show_name => show_name)
    showdate.valid_vouchers.create!(:vouchertype => bundle_component,
      :start_sales => 1.week.ago, :end_sales => 1.week.from_now, :max_sales_for_type => 100)
  end
  bundle.save!
end

Then /the "(.*)" bundle should (not )?include:/ do |name,no,tickets|
  bundle = Vouchertype.find_by(:name => name)
  bundle.should be_a_bundle
  included = bundle.included_vouchers
  tickets.hashes.each do |voucher|
    vouchertype = Vouchertype.find_by(:name => voucher['name'])
    id = vouchertype.id.to_s
    qty = voucher['quantity'].to_i
    if no
      included.should_not have_key(id)
    else
      included[id].should eq(qty)
    end
  end
end

Then /a vouchertype with name "(.*)" should (not )?exist/i do |name,no|
  @vouchertype = Vouchertype.find_by_name(name)
  if no then @vouchertype.should be_nil else @vouchertype.should be_a_kind_of(Vouchertype) end
end

Then /it should have a (.*) of (.*)/i do |attr,val|
  if val =~ /"(.*)"/
    @vouchertype.send(attr.downcase).to_s.should == val.to_s
  else
    @vouchertype.send(attr.downcase).should == val.to_i
  end
end

Then /it should be a (.*) voucher/i do |typ|
  @vouchertype.category.to_s.should == typ.downcase
end

When /I set end sales to "(.*)" minutes before show ?time/ do |minutes|
  fill_in "minutes_before", with: minutes
end

When /I choose to leave as-is on existing redemptions:\s+(.*)/ do |props|
  steps %Q{When I choose to overwrite existing redemptions}
  props.split(/\s*,\s*/).each do |prop|
    check "preserve_#{prop.gsub(/\s+/,'_')}"
  end
end

When /I choose to overwrite existing redemptions/ do
  %w(max_sales_for_type promo_code start_sales end_sales).each do |prop|
    uncheck "preserve_#{prop}"
  end
end

Then /(only )?the following voucher types should be valid for "(.*)":$/ do |only,show,tbl|
  show = Show.find_by!(:name => show)
  confirmed_vvs = tbl.hashes.map do |v|
    vv = begin
           ValidVoucher.find_by!(
        :showdate => Showdate.find_by!(:thedate => Time.zone.parse(v['showdate'])),
        :vouchertype => Vouchertype.find_by!(:name => v['vouchertype']))
         rescue ActiveRecord::RecordNotFound
           raise "Can't find valid_voucher for #{v['vouchertype']}:#{v['showdate']}"
         end
    expect(vv.end_sales).to eq(Time.zone.parse(v['end_sales']))
    expect(vv.max_sales_for_type).to eq(v['max_sales'].to_i)
    if v['promo_code']
      expect(vv.promo_code.to_s).to eq v['promo_code'].to_s
    end
    vv
  end
  # if checking to ensure these are the ONLY valid_vouchers:
  if only
    all_vvs_for_show = show.showdates.map(&:valid_vouchers).flatten.compact
    expect(all_vvs_for_show - confirmed_vvs).to be_empty
  end
end

Given /the following voucher types are valid for "(.*)":$/ do |show,tbl|
  show = Show.find_by!(:name => show)
  tbl.hashes.map do |v|
    ValidVoucher.create!(
      :showdate => Showdate.find_by!(:thedate => Time.zone.parse(v['showdate'])),
      :vouchertype => Vouchertype.find_by!(:name => v['vouchertype']),
      :start_sales => 1.hour.ago,
      :end_sales => Time.zone.parse(v['end_sales']),
      :promo_code => v['promo_code'],
      :max_sales_for_type => v['max_sales'].to_i)
  end
end

When /I select the following vouchertypes: (.*)/ do |vtypes|
  vtypes.split(/\s*,\s*/).each do |vtype|
    fullname = Vouchertype.where('name LIKE ?', vtype).first.name_with_season_and_price
    check(fullname)
  end
end

When /I select the following show dates: (.*)/ do |dates|
  dates.split(/\s*,\s*/).each do |date|
    check(Time.parse(date).to_formatted_s(:showtime_brief))
  end
end
