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
                  :subscriber => customer.is_subscriber?
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
                 :donation_chair => APP_CONFIG[:donation_ack_from]
                 )
  end
  
  def sending_to(recipient)
    @recipients = recipient.kind_of?(Customer)? recipient.login : recipient.to_s
    @from = 'AutoConfirm@audience1st.com'
    @headers = {}
    @subject = "#{APP_CONFIG[:venue]} - "
    @body = {
      :email => APP_CONFIG[:help_email],
      :phone => APP_CONFIG[:boxoffice_telephone],
      :venue => APP_CONFIG[:venue],
      :how_to_contact_us =>  @@contact_string
    }
  end
  
  @@contact_string = <<EOS
If this isn't correct, or if you have questions about your order or
any problems using our Web site, PLEASE DO NOT REPLY to this email
as it was generated automatically.

Instead, please email #{APP_CONFIG[:help_email]} or call #{APP_CONFIG[:boxoffice_telephone]}.

Thanks for your patronage!

#{APP_CONFIG[:venue]}
hosted by Audience1st LLC

EOS

end


