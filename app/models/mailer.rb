class Mailer < ActionMailer::Base

  helper :application
  helper :customers
  
  include CustomersHelper

  def confirm_account_change(customer, whathappened)
    sending_to(customer)
    @subject    << "#{customer.full_name}'s account"
    @body.merge!(
      :email         => customer.email,
      :question      => secret_question_text(customer.secret_question),
      :answer        => customer.secret_answer,
      :greeting      => customer.full_name,
      :whathappened  => whathappened,
      :provide_logout_url => true
    )
  end

  def send_new_password(customer, newpass, whathappened)
    sending_to(customer)
    @subject    << "#{customer.full_name}'s account"
    @body.merge!(
      :email         => customer.email,
      :newpass       => newpass,
      :question      => secret_question_text(customer.secret_question),
      :answer        => customer.secret_answer,
      :greeting      => customer.full_name,
      :whathappened  => whathappened,
      :provide_logout_url => true
    )
  end
    
  def confirm_order(customer, recipient, description, amount, payment_desc, special_instructions='')
    sending_to(customer)
    @subject << "order confirmation"
    @body.merge!(:greeting => customer.full_name,
                 :description => description,
                 :amount => amount,
                 :payment_desc => payment_desc,
                 :special_instructions => special_instructions
                 )
    @body[:recipient] = recipient if recipient != customer
  end

  def confirm_reservation(customer,showdate_id,num=1,confnum=0)
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
                 :confnum => confnum,
                 :subscriber => customer.subscriber?,
                 :notes => showdate.show.patron_notes
                  )
  end
    
  def cancel_reservation(old_customer, old_showdate, num = 1, confnum = 0)
    sending_to(old_customer)
    @subject << "CANCELLED reservation"
    @body.merge!(:showdate => old_showdate,
                 :num => num,
                 :confnum => confnum)
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
    @recipients = recipient.kind_of?(Customer)? recipient.email : recipient.to_s
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

  @@contact = []
  @@contact << "email #{Option.value(:help_email)}" unless Option.value(:help_email).blank?
  @@contact << "call #{Option.value(:boxoffice_telephone)}" unless Option.value(:boxoffice_telephone).blank?
  @@contact = @@contact.join(" or ")
  
  @@contact_string = <<EOS
If this isn't correct, or if you have questions about your order or
any problems using our Web site, PLEASE DO NOT REPLY to this email
as it was generated automatically.

Instead, please #{@@contact}.
Please include your name and login (as shown above), and if you're
experiencing technical problems, a description of the problem and the
type of browser and operating system you're using (Internet Explorer on
Windows, Safari or Firefox on Mac, etc.)

Thanks for your patronage!

#{Option.value(:venue)}
Powered by Audience1st

EOS

end


