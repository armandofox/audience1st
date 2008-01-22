class Mailer < ActionMailer::Base

  def send_new_password(customer, newpass, whathappened)
    sending_to(customer)
    @subject    << "#{customer.full_name}'s account"
    @body.merge!(
      :login         => customer.login,
      :newpass       => newpass,
      :greeting      => customer.full_name,
      :whathappened  => whathappened,
      :provide_logout_url => true
    )
  end

  def confirm_order(customer, description, amount, payment_desc)
    sending_to(customer)
    @subject << "order confirmation"
    @body.merge!(:greeting => customer.full_name,
                  :description => description,
                  :amount => amount,
                  :payment_desc => payment_desc
                  )
  end

  def confirm_reservation(customer,voucher)
    sending_to(customer)
    @subject  << "reservation confirmation"
    @body.merge!(:greeting => customer.full_name,
                 :performance => voucher.showdate.printable_name,
                 :subscriber => customer.is_subscriber?,
                 :notes => voucher.showdate.show.patron_notes
                  )
  end
    
  def cancel_reservation(old_customer, old_showdate)
    sending_to(old_customer)
    @subject << "CANCELLED reservation"
    @body.merge!(:showdate => old_showdate)
  end

  def donation_ack(customer,amount,nonprofit=true)
    sending_to(customer)
    @subject << "donation receipt"
    @body.merge!(:customer => customer,
                 :amount   => amount,
                 :nonprofit=> nonprofit,
                 :donation_chair => Option.value(:donation_ack_from)
                 )
  end
  
  def pending_followups(who, visits)
    # BUG: url_for doesn't work from script/runner since it doesn't
    #  know the hostname for the URL....removed for now
    #urls_for_visits = visits.map do |v|
    #url_for(:controller => 'visits', :action=>'list', :id=>v.customer)
    #end
    @recipients = who
    @from = 'AutoConfirm@audience1st.com' # bug
    @headers = {}
    @subject = "Followup visits reminder"
    @body = {
      :visits => visits,
      :who => who,
      :today => Time.now
    }
  end

  def sending_to(recipient)
    @recipients = recipient.kind_of?(Customer)? recipient.login : recipient.to_s
    @from = 'AutoConfirm@audience1st.com'
    @headers = {}
    @subject = "#{Option.value(:venue)} - "
    @body = {
      :email => Option.value(:help_email),
      :phone => Option.value(:boxoffice_telephone),
      :venue => Option.value(:venue),
      :how_to_contact_us =>  @@contact_string
    }
  end
  
  @@contact_string = <<EOS
If this isn't correct, or if you have questions about your order or
any problems using our Web site, PLEASE DO NOT REPLY to this email
as it was generated automatically.

Instead, please email #{Option.value(:help_email)} or call #{Option.value(:boxoffice_telephone)}.

Thanks for your patronage!

#{Option.value(:venue)}
hosted by Audience1st Inc.

EOS

end


