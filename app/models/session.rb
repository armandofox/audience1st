class Session < ActiveRecord::Base

  def self.num_active
    timeout = Option.value(:session_timeout).to_i
    timeout = 1 if timeout < 1
    Session.count(:conditions => ['updated_at > ?', timeout.minutes.ago])
  end

  def self.reap_inactive
    older_than = APP_CONFIG[:session_reap].to_i.days.ago.to_formatted_s(:db)
    Session.delete_all("updated_at < '#{older_than}'")
  end

end
