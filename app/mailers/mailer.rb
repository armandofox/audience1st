class Mailer < ActionMailer::Base

  default :from => "AutoConfirm-#{Option.venue_shortname}@audience1st.com"
  
  before_filter :setup_defaults

  def confirm_account_change(customer, whathappened, newpass=nil)
    @whathappened = whathappened
    @newpass = newpass
    mail(:to => @email, :subject => "#{@subject} #{customer.full_name}'s account")
  end

    
  def confirm_order(order) 
    @order = order
    mail(:to => @order.purchaser, :subject => "#{@subject} order confirmation")
  end

  def confirm_reservation(customer,showdate,num=1)
    @customer = customer
    @showdate = showdate
    @num = num
    @notes = @showdate.show.patron_notes
    mail(:to => customer.email, :subject => "#{@subject} reservation confirmation")
  end
    
  def cancel_reservation(old_customer, old_showdate, num = 1, confnum)
    @showdate,@customer = old_showdate, old_customer
    @num,@confnum = num,confnum
    mail(:to => @customer.email, :subject => "#{@subject} CANCELLED reservation")
  end

  def donation_ack(customer,amount,nonprofit=true)
    @customer,@amount,@nonprofit = customer, amount, nonprofit
    @donation_chair = Option.donation_ack_from
    mail(:to => @customer.email, :subject => "#{@subject} Thank you for your donation!")
  end
  
  def upcoming_birthdays(send_to, num, from_date, to_date, customers)
    @num,@from_date,@to_date,@customers = num,from_date,to_date,customers
    @subject << "Birthdays between #{from_date.strftime('%x')} and #{to_date.strftime('%x')}"
    mail(:to => send_to, :subject => @subject)
  end

  protected
  
  def setup_defaults
    @venue = Option.venue
    @subject = "#{@venue} - "
    @contact = if Option.help_email.blank?
               then "call #{Option.boxoffice_telephone}"
               else "email #{Option.help_email} or call #{Option.boxoffice_telephone}"
               end
  end
end


