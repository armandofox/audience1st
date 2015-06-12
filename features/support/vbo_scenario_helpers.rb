module VboScenarioHelpers
  
  def setup_show_and_showdate(name,time,args={})
    show = Show.find_by_name(name) ||
      Show.create!(:name => name,
      :house_capacity => args[:house_capacity] || 10,
      :opening_date => args[:opening_date] || (time - 1.month),
      :closing_date => args[:closing_date] || (time + 1.month))
    return Showdate.find_by_show_id_and_thedate(show.id, time) ||
      show.showdates.create!(
      :thedate => time,
      :end_advance_sales => time - 5.minutes,
      :max_sales => args[:max_sales] || 100)
  end

  def make_valid_tickets(showdate,vtype,qty=nil)
    qty ||= showdate.max_allowed_sales
    showdate.valid_vouchers.create!(:vouchertype => vtype,
      :max_sales_for_type => qty.to_i,
      :end_sales => showdate.thedate + 5.minutes,
      :start_sales => [Time.now - 1.day, showdate.thedate - 1.week].min
      )
  end

  def setup_subscriber_tickets(customer, show, num)
    showdates = show.showdates
    sub_vouchertype = create(:vouchertype_included_in_bundle, :name => "#{show.name} (Subscriber)")
    sub_vouchers = create_list(:subscriber_voucher, num.to_i, :vouchertype => sub_vouchertype, :customer => customer)
    showdates.each { |s| make_valid_tickets s, sub_vouchertype }
    sub_vouchers
  end

  def create_tickets(hashes)
    tickets_hashes = {}
    show = nil
    showdate = nil
    hashes.each do |t|
      thedate = Time.parse t[:showdate]
      show ||= t[:show]
      showdate ||= thedate
      sd = Showdate.find_by_thedate(thedate) ||
        create(:showdate, :thedate => Time.parse(t[:showdate]), :show_name => t[:show])
      vt = Vouchertype.find_by_name(t[:type]) ||
        create(:revenue_vouchertype, :name => t[:type], :price => t[:price])
      create(:valid_voucher, :vouchertype => vt, :showdate => sd, :max_sales_for_type => t[:qty])
      tickets_hashes["#{t[:type]} - #{number_to_currency t[:price].to_f}"] = t[:qty]
      # show,qty,type,price,showdate = t.values_at(:show, :qty, :type,:price,:showdate)
      # steps %Q{Given a show "#{show}" with #{10+qty.to_i} "#{type}" tickets for $#{price} on "#{showdate}"}
    end
    visit path_to %Q{the store page for "#{show}"}
    select show, :from => 'Show'
    select_date_matching showdate, :from => 'Date'
    tickets_hashes.each_pair do |type,qty|
      select qty, :from => type
    end
  end
end

World(VboScenarioHelpers)
