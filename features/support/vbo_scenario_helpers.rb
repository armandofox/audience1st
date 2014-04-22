module VboScenarioHelpers
  
  def setup_show_and_showdate(name,time,args={})
    show = Show.find_by_name(name) ||
      Show.create!(:name => name,
      :house_capacity => args[:house_capacity] || 10,
      :opening_date => args[:opening_date] || 1.month.ago,
      :closing_date => args[:closing_date] || 1.month.from_now)

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

  def create_tickets(hashes)
    hashes.each do |t|
      show,qty,type,price,showdate = t.values_at(:show, :qty, :type,:price,:showdate)
      Given %Q{a show "#{show}" with #{10+qty.to_i} "#{type}" tickets for $#{price} on "#{showdate}"}
      visit path_to %Q{the store page for "#{show}"}
      select show, :from => 'Show'
      select_date_matching showdate, :from => 'Date'
      select qty, :from => "#{type} - $#{price}"
    end
  end
end

World(VboScenarioHelpers)
