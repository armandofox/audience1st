class Mailer < ActionMailer::Base

  helper :customers, :application, :options

  # the default :from needs to be wrapped in a callable because the dereferencing of Option may
  #  cause an error at class-loading time.
  default :from => Proc.new { "AutoConfirm@#{Option.sendgrid_domain}" }

  before_action :setup_defaults

  def email_test(destination_address)
    @time = Time.now
    mail(:to => destination_address, :subject => 'Testing')
  end
  
  def confirm_account_change(customer, whathappened, newpass=nil)
    @whathappened = whathappened
    @newpass = newpass
    @customer = customer
    mail(:to => customer.email, :subject => "#{@subject} #{customer.full_name}'s account")
  end

    
  def confirm_order(purchaser,order) 
    @order = order
    mail(:to => purchaser.email, :subject => "#{@subject} order confirmation")
  end

  def confirm_reservation(customer,showdate,num=1)
    @customer = customer
    @showdate = showdate
    @num = num
    @notes = @showdate.patron_notes
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
    @num,@customers = num,customers
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
    setup_delivery_params
  end

  def setup_delivery_params
    if (Option.sendgrid_key_value.blank? or
        Option.sendgrid_domain.blank?)
      Rails.application.config.action_mailer.perform_deliveries = false
      Rails.logger.info "NOT sending email"
    else
      Rails.logger.info "Setting up sendgrid"
      Rails.application.config.action_mailer.perform_deliveries = true
      Rails.application.config.action_mailer.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = {
        :user_name => 'apikey',
        :password => Option.sendgrid_key_value,
        :domain   => Option.sendgrid_domain,
        :address  => 'smtp.sendgrid.net',
        :port     => 587,
        :enable_starttls_auto => true,
        :authentication => :plain
      }
    end
  end
end


