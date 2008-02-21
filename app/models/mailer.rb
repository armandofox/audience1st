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

  def confirm_reservation(customer,showdate_id,num=1)
    sending_to(customer)
    begin
      showdate = Showdate.find(showdate_id)
    rescue
      raise "No such showdate #{showdate_id} confirming to #{@recipients}"
      return
    end
    @subject  << "reservation confirmation"
    @body.merge!(:greeting => customer.full_name,
                 :performance => showdate.printable_name,
                 :num => num,
                 :subscriber => customer.is_subscriber?,
                 :notes => showdate.show.patron_notes
                  )
  end
    
  def cancel_reservation(old_customer, old_showdate, num = 1)
    sending_to(old_customer)
    @subject << "CANCELLED reservation"
    @body.merge!(:showdate => old_showdate,
                 :num => num)
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
    @from = @@from_addr # bug
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
    @from = @@from_addr
    @headers = {}
    @subject = "#{Option.value(:venue)} - "
    @body = {
      :email => Option.value(:help_email),
      :phone => Option.value(:boxoffice_telephone),
      :venue => Option.value(:venue),
      :how_to_contact_us =>  @@contact_string
    }
  end
  
  @@from_addr = "AutoConfirm-#{Option.value(:venue_shortname)}@audience1st.com"

  @@contact_string = <<EOS
If this isn't correct, or if you have questions about your order or
any problems using our Web site, PLEASE DO NOT REPLY to this email
as it was generated automatically.

Instead, please email #{Option.value(:help_email)} or call #{Option.value(:boxoffice_telephone)}.

Thanks for your patronage!

#{Option.value(:venue)}
Powered by Audience1st

EOS

end


