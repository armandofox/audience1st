module ScenarioHelpers
  module Orders
    def buy!(customer, vtype, qty, showdate=nil)
      @order = build(:order,
        :purchasemethod => Purchasemethod.get_type_by_name('box_cash'),
        :customer => customer,
        :purchaser => customer)
      @order.vouchers = []
      vv = create(:valid_voucher, :vouchertype => vtype, :showdate => showdate,
        :start_sales => Time.at_beginning_of_season(vtype.season),
        :end_sales => Time.at_end_of_season(vtype.season))
      @order.add_tickets(vv, qty.to_i)
      @order.purchasemethod = Purchasemethod.get_type_by_name('none') if @order.total_price.zero?
      @order.finalize!
    end
  end
end

World(ScenarioHelpers::Orders)

Given /^an order for customer "(.*)" paid with "credit card" containing:$/ do |customer, table|
  step %Q{I am logged in as customer "#{customer}"}
  step(%Q{my cart contains the following tickets:}, table)
  step %Q{I place my order with a valid credit card}
end

Given /^a comp order for customer "(.*) (.*)" containing (\d+) "(.*)" comps to "(.*)"$/ do |first,last, qty, comp_type, show_name|
  comp = create(:comp_vouchertype, :name => comp_type)
  sd = create(:showdate, :show_name => show_name)
  customer = find_or_create_customer first,last
  buy!(customer, comp, qty.to_i, sd)
end

Given /^an order of (\d+) "(.*)" comp subscriptions for customer "(.*) (.*)"$/ do |qty, sub, first, last|
  customer = find_or_create_customer first,last
  buy!(customer, Vouchertype.find_by!(:name => sub), qty.to_i)
end

Given /^that order has the comment "(.*)"$/ do |comment|
  @order.update_attributes!(:comments => comment)
end

Then /^I should see the following details for that order:$/ do |table|
  within("div#details_order_#{@order.id}") do
    table.hashes.each do |h|
      page.should have_content h[:content]
    end
  end
end

Given /^customer "(.*) (.*)" has the following (subscriber )?reservations:/ do |first,last,sub,table|
  customer = find_or_create_customer(first,last)
  table.hashes.each do |res|
    vtype = find_or_create_or_default res[:vouchertype], (sub ? :vouchertype_included_in_bundle : :revenue_vouchertype)
    showdate = setup_show_and_showdate(res[:show], res[:showdate])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => showdate)
    purchasemethod = purchasemethod_from_string res[:purchasemethod]
    order = build(:order, :customer => customer, :purchaser => customer, :purchasemethod => purchasemethod)
    order.add_tickets(vv, res[:qty].to_i)
    order.finalize!
  end
end

Given /^an order for customer "(.*) (.*)" containing the following tickets:/ do |first,last,table|
  customer = find_or_create_customer(first,last)
  # make it legal for customer to buy the things
  @order = build(:order,
    :purchasemethod => Purchasemethod.get_type_by_name('box_cash'),
    :customer => customer,
    :purchaser => customer)
  @order.vouchers = []
  table.hashes.each do |voucher|
    vtype = Vouchertype.find_by_name(voucher[:name]) || create(:revenue_vouchertype, :name => voucher[:name])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => nil)
    @order.add_tickets(vv, voucher[:quantity].to_i)
  end
  @order.finalize!
end

Then /^customer "(.*) (.*)" should have an order (with comment "(.*)" )?containing the following tickets:$/ do |first,last,comments,table|
  @customer = find_customer(first,last)
  order = @customer.orders.first
  order.comments.should == comments
  table.hashes.each do |item|
    matching_items = order.vouchers.select { |v| v.vouchertype.name == item['type'] }
    unless item['showdate'].blank?
      matching_items.reject! { |v| v.showdate != Showdate.find_by_thedate(Time.zone.parse(item['showdate'])) }
    end
    matching_items.length.should == item['qty'].to_i
  end
end

Given /^the following orders have been placed:/ do |tbl|
  # fields: date, customer name, item1 (eg "2x SeasonSub"), item2 (eg "$20 donation"), payment
  tbl.hashes.each do |order|
    pmt_types = {"credit card" => "web_cc", "cash" => "box_cash", "check" => "box_chk", "comp" => "none"}.freeze
    customer = find_or_create_customer(*(order['customer'].split(/\s+/)))
    o = build(:order,
      :purchasemethod => Purchasemethod.get_type_by_name(pmt_types[order['payment']]),
      :purchase_args => {:credit_card_token => 'DUMMY'}, # to pass order validation for CC purchase
      :customer => customer, :purchaser => customer)
    [order['item1'],order['item2']].each do |item|
      case item
      when /\$(\d+) donation/
        o.add_donation(Donation.from_amount_and_account_code_id($1.to_i,
            Option.default_donation_account_code))
      when /(\d+)x (.*)$/
        vv = create(:valid_voucher, :vouchertype => Vouchertype.find_by!(:name => $2))
        o.add_tickets(vv, $1.to_i)
      end
    end
    o.finalize!
    o.update_attribute(:sold_on,Time.zone.parse(order['date']))
  end
end

When /^I (?:refund|cancel) items? (.*) of that order$/ do |items|
  steps %Q{
    When I select items #{items} of that order
    And I refund that order
}
end

When /^I refund that order$/ do
  @order.should be_a_kind_of Order # setup by a previous step
  within "#order_#{@order.id}" do
    find('input#refund').click
  end
end

When /^I (un)?select all the items in that order$/ do |un|
  page.all(:css, 'input.itemSelect').each do |e|
    if un then uncheck e['id'] else check e['id'] end
  end
end

When /^I (un)?select items? ([0-9, ]+) of that order$/ do |un, index|
  index.split(/, */).each do |i|
    if un then uncheck("items_#{i}") else check("items_#{i}") end
  end
end

When /^I check the transfer box for the (\d)(?:th|st|rd) "(.*)" voucher$/ do |ordinal,voucher_name|
  ordinal = ordinal.to_i
  raise "Can only get first element right now" unless ordinal==1
  td = "//table[@id='transfer_vouchers_table']//td[contains(text(),'#{voucher_name}')]"
  # navigate from the td to the checkbox at the beginning of its row
  checkbox = "#{td}/..//input[@type='checkbox']"
  find_all(:xpath, checkbox)[ordinal - 1].set(true)
end
