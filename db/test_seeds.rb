time = Time.new(2017, 9, 31, 2, 2, 2, "+02:00")
#NOT SURE IF LISTING DATE IS RIGHT ASK FOX 
show = Show.create(
      :name => "New Show",
      :house_capacity =>  10,
      :opening_date =>  (time - 2.month),
      :closing_date => (time + 2.month), 
      :listing_date => time)
show.save
showdate = show.showdates.create!(
      :thedate => time,
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

  customer = create(:customer, :first_name => first, :last_name => last)
  vtype = Vouchertype.find_by_name(type) || create(:revenue_vouchertype, :name => type)
  vv = ValidVoucher.find_by_vouchertype_id_and_showdate_id(vtype.id,@showdate.id) ||
    create(:valid_voucher, :vouchertype => vtype, :showdate => @showdate)
  order = build(:order,
    :purchasemethod => Purchasemethod.find_by_shortdesc('box_cash'),
    :customer => customer,
    :purchaser => customer)
  order.add_tickets(vv, num.to_i)
  order.finalize!



  order = Order.new(
    :purchasemethod => Purchasemethod.find_by_shortdesc('box_cash'),
    :customer => customer,
    :purchaser => customer)

order.add_tickets(vv, 100)
  order.finalize!












