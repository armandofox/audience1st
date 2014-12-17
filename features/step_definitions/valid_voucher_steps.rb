#  @showdate is set by the function that most recently created a showdate for a scenario

Given /^sales cutoff at "(.*)", with "(.*)" tickets selling from (.*) to (.*)$/ do |end_advance_sales, vouchertype_name, start_sales, end_sales|
  vtype = Vouchertype.find_by_name!(vouchertype_name)
  vtype.valid_vouchers = []
  vtype.valid_vouchers <<
    ValidVoucher.new(
    :showdate => @showdate,
    :start_sales => Time.parse(start_sales),
    :end_sales   => Time.parse(end_sales)
    )
  @showdate.update_attributes!(:end_advance_sales => end_advance_sales)
end

Given /^there are (\d+) "(.*)" tickets and (\d+) total seats available$/ do |per_ticket_limit, vouchertype_name, seat_limit|
  vtype = Vouchertype.find_by_name!(vouchertype_name)
  vtype.valid_vouchers = []
  vtype.valid_vouchers <<
    ValidVoucher.new(
    :showdate => @showdate,
    :start_sales => 1.week.ago,
    :end_sales   => @showdate.thedate,
    :max_sales_for_type => per_ticket_limit
    )
  @showdate.update_attributes!(:max_sales => seat_limit)
end
