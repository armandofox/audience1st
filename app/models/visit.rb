class Visit < ActiveRecord::Base
  belongs_to :customer
  validates_associated :customer
  validates_columns :contact_method, :purpose, :result

  include Comparable
  def <=>(other_visit)
    thedate <=> other_visit.thedate
  end

  def name_for(id, default_str="NOT FOUND: %s")
    id.zero? ? "???" :
      begin
        Customer.find(id).full_name
      rescue Exception => e
        logger.error("Lookup customer_id #{id}: #{e.message}")
        sprintf(default_str, e.message)
      end
  end

  def visited_by ;   name_for(visited_by_id) ;  end

  def followup_by ; name_for(followup_assigned_to_id) ; end

  def summarize(arg=:thedate)
    "#{self.visited_by} on #{self.send(arg).to_formatted_s(:short)}"
  end
end
