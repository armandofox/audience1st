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
    venue = Option.venue
    subject = "#{venue} - "

    n = Option.send_birthday_reminders
    recipient = Option.boxoffice_daemon_notify
    now = Time.current.at_beginning_of_day
    return if n <= 0 || now.strftime('%j').to_i % n != 0 || recipient.blank?
    from_date = now + n.days
    to_date = from_date + n.days
    customers = Customer.birthdays_in_range(from_date, to_date)
    unless customers.empty?
      subject << "Birthdays between #{from_date.strftime('%x')} and #{to_date.strftime('%x')}"
      NotifyBoxOfficeManager.notify("upcoming_birthdays", 
                           {:num => n, :customers => customers, :recipient => recipient}, 
                           subject)
    end
  end
end

      
