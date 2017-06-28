class Customer < ActiveRecord::Base

  # force birthday year to a fixed value, since we don't care about birth year,
  # to simplify comparisons
  BIRTHDAY_YEAR = 2000
  def force_birthday_year
    self.birthday = birthday.change(:year => BIRTHDAY_YEAR) unless birthday.blank?
  end

  before_save :force_birthday_year

  def self.birthdays_in_range(from,to)
    from = from.change(:year => BIRTHDAY_YEAR)
    to = to.change(:year => BIRTHDAY_YEAR)
    Customer.where("birthday BETWEEN ? AND ?", from, to)
  end

  def self.notify_upcoming_birthdays
    n = Option.send_birthday_reminders.to_i
    recipient = Option.boxoffice_daemon_notify.to_s
    from = Date.today + n.days
    to = from + n.days
    return unless n > 0 && recipient.match(/\S+@\S+/) &&
      from.strftime('%j').to_i % n == 0
    customers = self.birthdays_in_range(from, to)
    unless customers.empty?
      Mailer.upcoming_birthdays(recipient, from, to, customers).deliver_now
    end
  end
end

      
