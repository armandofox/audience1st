require 'digest/sha2'

class Mailer < ActionMailer::Base

  helper :customers, :application, :options

  # the default :from needs to be wrapped in a callable because the dereferencing of Option may
  #  cause an error at class-loading time.
  default :from => Proc.new { "AutoConfirm@#{Option.sender_domain}" }
  default :reply_to => Proc.new { Option.box_office_email }
  # Prevent ActionMailer from constructing invalid message-IDs in which the domain doesn't match
  default "Message-ID" => Proc.new { "<#{Digest::SHA2.hexdigest(Time.current.to_i.to_s)}@#{Figaro.env.MAILGUN_DOMAIN}>" }
  # include to get past many spam filters
  default "List-Unsubscribe" => Proc.new { "<mailto:#{Option.box_office_email}>" }

  before_action :set_delivery_options

  BODY_TAG = '=+MESSAGE+='
  FOOTER_TAG = '=+FOOTER+='
  
  def email_test(destination_address)
    @time = Time.current
    render_and_send_email(destination_address, 'Test email', :email_test)
  end
  
  def confirm_account_change(customer, whathappened, token=nil, requestURL=nil)
    @whathappened = whathappened
    if requestURL
      uri = URI(requestURL)
      @token_link = reset_token_customers_url(:token => token, :host => uri.host, :protocol => uri.scheme)
    end
    @customer = customer
    render_and_send_email(customer.email, "#{@subject} #{customer.full_name}'s account", :confirm_account_change)
  end

  def confirm_order(purchaser,order)
    @order = order
    # show-specific notes
    @notes = @order.collect_notes.join("\n\n")
    render_and_send_email(purchaser.email, "#{@subject} order confirmation", :confirm_order)
  end

  def confirm_reservation(customer,showdate,vouchers)
    @customer = customer
    @showdate = showdate
    @seats = Voucher.seats_for(vouchers)
    @notes = @showdate.patron_notes if @showdate
    render_and_send_email(customer.email,"#{@subject} reservation confirmation", :confirm_reservation)
  end

  def cancel_reservation(old_customer, old_showdate, seats)
    @showdate,@customer = old_showdate, old_customer
    @seats = seats
    render_and_send_email(@customer.email, "#{@subject} CANCELLED reservation", :cancel_reservation)
  end

  def upcoming_birthdays(num, customers, subject, recipient)
    @num = num
    @customers = customers
    render_and_send_email(recipient, subject, :upcoming_birthdays)
  end
  
  def general_mailer(template_name, params, subject)
    params.keys.each do |key|
      self.instance_variable_set("@#{key}", params[key])
    end
    @subject << subject 
    mail(:to => params[:recipient],
             :subject => @subject, 
             :template_name => template_name)        
  end

  protected

  def render_and_send_email(address, subject, body_template)
    body_as_string =
      %Q{<div class="a1-email-body #{body_template}">\n}.html_safe  <<
      render_to_string(:action => body_template, :layout => false).html_safe  <<
      %Q{</div>}.html_safe
    html = Option.html_email_template.
             gsub(BODY_TAG, body_as_string).
             gsub(FOOTER_TAG, render_to_string(:partial => 'contact_us', :layout => false))
    text = ActionController::Base.helpers.strip_tags(body_as_string)
    
    mail(:to => address, :subject => subject) do |fmt|
      fmt.text { render :inline => text }
      fmt.html { render :inline => html }
    end
  end

  def set_delivery_options
    @venue = Option.venue
    @subject = "#{@venue} - "
    if Rails.env.production? and Option.sender_domain.blank?
      ActionMailer::Base.perform_deliveries = false
      Rails.logger.info "NOT sending email"
    else
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.smtp_settings = {
        :port           => 587,
        :address        => 'smtp.mailgun.org',
        :user_name      => Figaro.env.MAILGUN_SMTP_LOGIN,
        :password       => Figaro.env.MAILGUN_SMTP_PASSWORD,
        :domain         => Option.sender_domain,
        :authentication => :plain
      }
    end
  end
end
