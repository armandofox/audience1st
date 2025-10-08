module VboScenarioHelpers

  def purchasemethod_from_string(str)
    case str
    when /(at )?box office/i then Purchasemethod.get_type_by_name('web_cc')
    when /credit card/i then Purchasemethod.get_type_by_name('web_cc')
    else Purchasemethod.get_type_by_name('box_cash')
    end
  end

  def find_or_create_or_default(vtype_name, type = :revenue_voucher)
    if vtype_name.blank?
      create(type)
    else
      Vouchertype.find_by_name(vtype_name) ||
        create(type, :name => vtype_name)
    end
  end

  def setup_show_and_showdate(name,time)
    time = Time.zone.parse(time) unless time.kind_of? Time
    show = Show.find_by_name(name) || create(:show, :name => name, :season => time.year)
    return Showdate.find_by(:show_id => show.id, :thedate => time) ||
      create(:showdate, :show => show, :thedate => time)
  end

  def make_valid_tickets(showdate,vtype,qty=nil,promo_code=nil)
    qty ||= showdate.max_advance_sales
    options = {:vouchertype => vtype,
      :max_sales_for_type => qty.to_i,
      :end_sales => showdate.thedate - 1.minute,
      :start_sales => [Time.current - 1.day, showdate.thedate - 1.week].min
    }
    options[:promo_code] = promo_code if promo_code
    showdate.valid_vouchers.create! options
  end

  def setup_subscriber_tickets(customer, num, show, changeable: false)
    vouchertype_name = "#{show.name} (Subscriber)"
    sub_vouchertype = Vouchertype.find_by(:name => vouchertype_name) || create(:vouchertype_included_in_bundle, :name => vouchertype_name, :changeable => changeable)
    sub_vouchers = create_list(:subscriber_voucher, num.to_i, :vouchertype => sub_vouchertype, :customer => customer)
    show.showdates.each { |s| make_valid_tickets s, sub_vouchertype }
    create(:order, :items => sub_vouchers, :customer => customer, :sold_on => Time.current.yesterday)
    sub_vouchers
  end

  def sell_tickets(vtype, dt, order, args={})
    # args must include either :quantity => n  or :seats => ['A1','A2'] but not both
    msg = RuntimeError.new("Must specify either :qty or :seats but not both")
    raise msg unless args.has_key?(:qty) ^ args.has_key?(:seats)
    if args.has_key?(:qty)
      qty,seats = args[:qty].to_i, []
    else
      seats = args[:seats]
      qty = seats.length
    end
    showdate = Showdate.find_by_thedate!(Time.zone.parse(dt))
    offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
      Vouchertype.find_by_name!(vtype).id,
      showdate.id)
    order.add_tickets_without_capacity_checks(offer, qty, seats)
    order.finalize!
    order
  end

  def create_tickets(hashes, customer=nil)
    tickets_hashes = {}
    show = nil
    showdate = nil
    comments = ''
    hashes.each do |t|
      thedate = Time.zone.parse t[:showdate]
      show ||= t[:show]
      showdate ||= thedate
      comments += t[:comments].to_s
      sd = Showdate.find_by_thedate(thedate) ||
        create(:showdate, :thedate => Time.zone.parse(t[:showdate]), :show_name => t[:show])
      vt = Vouchertype.find_by_name(t[:type]) ||
        create(:revenue_vouchertype, :name => t[:type], :price => t[:price])
      unless ValidVoucher.find_by(:vouchertype => vt, :showdate => sd)
        create(:valid_voucher, :vouchertype => vt, :showdate => sd, :max_sales_for_type => t[:qty].to_i)
      end
      tickets_hashes["#{t[:type]} - #{number_to_currency t[:price].to_f}"] = t[:qty].to_i
      # show,qty,type,price,showdate = t.values_at(:show, :qty, :type,:price,:showdate)
      # steps %Q{Given a show "#{show}" with #{10+qty.to_i} "#{type}" tickets for $#{price} on "#{showdate}"}
    end
    if customer
      visit path_to %Q{the store page for the show "#{show}" for customer "#{customer}"}
    else
      visit path_to %Q{the store page for the show "#{show}"}
    end
    select show, :from => 'Show'
    select_date_matching showdate, :from => 'Date'
    fill_in "comments", :with => comments
    tickets_hashes.each_pair do |type,qty|
      begin
        select qty.to_s, :from => type
      rescue Capybara::ElementNotFound # for admin, fill in box rather than dropdown
        fill_in type, :with => qty.to_s
      end
    end
  end
end

World(VboScenarioHelpers)
