module VboScenarioHelpers
  def process_tickets(hashes)
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
