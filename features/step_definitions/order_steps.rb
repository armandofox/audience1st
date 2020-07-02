module ScenarioHelpers
  module Orders
    def buy!(customer, vtype, qty, showdate: nil, seats: [])
      @order = create(:order,
        :purchasemethod => Purchasemethod.get_type_by_name('box_cash'),
        :customer => customer,
        :purchaser => customer)
      @order.vouchers = []
      vv = ValidVoucher.find_by(:vouchertype => vtype, :showdate => showdate) ||
        create(:valid_voucher, :vouchertype => vtype, :showdate => showdate,
        :start_sales => Time.at_beginning_of_season(vtype.season),
        :end_sales => Time.at_end_of_season(vtype.season))
      @order.add_tickets_without_capacity_checks(vv, qty.to_i, seats)
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

Given /^a comp order for customer "(.*) (.*)" containing (\d+) "(.*)" comps? to "(.*)"$/ do |first,last, qty, comp_type, show_name|
  comp = create(:comp_vouchertype, :name => comp_type)
  sd = create(:showdate, :show_name => show_name)
  customer = find_or_create_customer first,last
  buy!(customer, comp, qty.to_i, showdate: sd)
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

Then /^I should not see the following details for that order:$/ do |table|
  within("div#details_order_#{@order.id}") do
    table.hashes.each do |h|
      expect(page).not_to have_content(h[:content])
    end
  end
end

Given /^an order for customer "(.*) (.*)" containing the following tickets:/ do |first,last,table|
  customer = find_or_create_customer(first,last)
  # make it legal for customer to buy the things
  @order = create(:order,
    :purchasemethod => Purchasemethod.get_type_by_name('box_cash'),
    :customer => customer,
    :purchaser => customer)
  @order.vouchers = []
  table.hashes.each do |voucher|
    vtype = Vouchertype.find_by_name(voucher[:name]) || create(:revenue_vouchertype, :name => voucher[:name])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => nil)
    @order.add_tickets_without_capacity_checks(vv, voucher[:quantity].to_i)
  end
  @order.finalize!
end

Given /^the following orders have been placed:/ do |tbl|
  # fields: date, customer name, item1 (eg "2x SeasonSub"), item2 (eg "$20 donation"), payment
  tbl.hashes.each do |order|
    pmt_types = {"credit card" => "web_cc", "cash" => "box_cash", "check" => "box_chk", "comp" => "none"}.freeze
    customer = find_or_create_customer(*(order['customer'].split(/\s+/)))
    @order = create(:order,
      :purchasemethod => Purchasemethod.get_type_by_name(pmt_types[order['payment']]),
      :purchase_args => {:credit_card_token => 'DUMMY'}, # to pass order validation for CC purchase
      :customer => customer, :purchaser => customer)
    [order['item1'],order['item2']].each do |item|
      case item
      when /\$(\d+) donation/
        @order.add_donation(Donation.from_amount_and_account_code_id($1.to_i,
            Option.default_donation_account_code))
      when /(\d+)x (.*)$/
        vv = create(:valid_voucher, :vouchertype => Vouchertype.find_by!(:name => $2))
        @order.add_tickets_without_capacity_checks(vv, $1.to_i)
      end
    end
    @order.finalize!(Time.zone.parse(order['date']))
  end
end

When /^I (?:refund|cancel) items? (.*) of (?:that )?order ?(\d*)?$/ do |items,ord_id|
  @order = Order.find(ord_id) unless ord_id.blank?
  visit order_path(@order)
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
    if un then uncheck e['id'].to_s else check e['id'].to_s end
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

Then /^there should be refund items for that order with amounts:(.*)/ do |list|
  amounts = list.strip.split(/\s*,\s*/).map(&:to_f).sort.map { |x| -x }
  order_item_ids = @order.items.where('type != "RefundedItem"').map(&:id)
  refunds = RefundedItem.where(:order_id => @order.id, :bundle_id => order_item_ids).order(:amount)
  expect(amounts.count).to eq(refunds.count)
end

Then /^there should be no refund items for that order/ do
  expect(@order.items.where('type = "RefundedItem"').count).to eq(0)
end
