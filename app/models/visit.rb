class Visit < ActiveRecord::Base
  belongs_to :customer
  validates_associated :customer
  validates_columns :contact_method, :purpose, :result
  include Enumerable
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

  # this is a class method because it's called via script/runner from
  # a cron job.  Identify all visits that have a followup due in the next
  # followup_visit_reminder_lead_time days;
  #  group by whose job it is to followup; and send emails.
  def self.notify_pending_followups
    # if followup_reminder_lead_time option is 0, don't even do this.
    return if (d = Option.value(:followup_visit_reminder_lead_time)).zero?
    logger.info "#{Time.now.to_formatted_s(:short)}: Generating pending followups"
    start = Time.now
    nd = start + d.days
    vs = Visit.find(:all,
                    :conditions => ["followup_date BETWEEN ? AND ?",start,nd],
                    :order => 'followup_date')
    logger.info "#{vs.length} followups to report"
    unless vs.empty?
      # group them by who's responsible
      vs.group_by(&:followup_assigned_to_id).each_pair do |who,visits|
        w = Customer.find(who)
        logger.info "#{visits.length} for #{w.full_name} <#{w.login}>"
        Mailer.deliver_pending_followups(w.login, visits) 
      end
    end
  end
  
end
