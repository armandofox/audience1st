customer = Customer.create(:first_name => "a", :last_name => "l", :email => "b@gmail.com", :password => "jjjjjj")
time = Time.new(2017, 10, 16, 2, 2, 2, "+02:00")
showtime = Time.now + 30.minutes

#NOT SURE IF LISTING DATE IS RIGHT ASK FOX
show = Show.create(
      :name => "Full Season",
      :house_capacity =>  10,
      :opening_date =>  (time - 2.month),
      :closing_date => (time + 2.month),
      :listing_date => time)
show.save
showdate = show.showdates.create!(
      :thedate => showtime,
      :end_advance_sales => time - 5.minutes,
      :max_sales => 100)
showdate.save
#'comp' or 'revenue'
#also Vouchertype::BOXOFFICE
vtype = Vouchertype.create!(
    :name => "Regular",
    :price => 100,
    :season => time.year,
    :walkup_sale_allowed => true,
    :category => 'revenue',
    :offer_public => Vouchertype::ANYONE)
vtype2 = Vouchertype.create!(
    :name => "Subscriber",
    :price => 100,
    :season => time.year,
    :walkup_sale_allowed => true,
    :category => 'revenue',
    :offer_public => Vouchertype::ANYONE)

showdate.valid_vouchers.create!(:vouchertype => vtype,
      :max_sales_for_type => 100,
      :end_sales => showdate.thedate + 5.minutes,
      :start_sales => [Time.now - 1.day, showdate.thedate - 1.week].min
      )

showdate.valid_vouchers.create!(:vouchertype => vtype2,
      :max_sales_for_type => 100,
      :end_sales => showdate.thedate + 5.minutes,
      :start_sales => [Time.now - 1.day, showdate.thedate - 1.week].min
      )


  order = Order.create(
    :purchasemethod => Purchasemethod.find_by_shortdesc('box_cash'),
    :customer => customer,
    :purchaser => customer)
  order.vouchers = []
  vtype3 = Vouchertype.create(:category => "revenue", :name => "Full Season", :season => time)
  vv = ValidVoucher.create(:vouchertype => vtype3, :showdate => nil, :start_sales => time-1.days, :end_sales => time + 30.days)
  puts(vv.save)
  puts(vv.errors.full_messages)
  vtype3.save
  order.add_tickets(vv, 5)
  order.finalize!
  puts(order.errors.full_messages)
