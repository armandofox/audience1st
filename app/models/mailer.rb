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
    
  def confirm_order(customer, order) 
    sending_to(customer)
    @subject << "order confirmation"
    @body.merge!(:greeting => customer.full_name,
                 :description => order.summary,
                 :amount => order.total_price,
                 :payment_desc => order.purchasemethod.description,
                 :special_instructions => order.comments
                 )
    @body[:recipient] = order.customer if order.gift?
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
                 :venue => Option.venue,       
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
                 :donation_chair => Option.donation_ack_from
                 )
  end
  
  def pending_followups(who, visits)
    # BUG: url_for doesn't work from script/runner since it doesn't
    #  know the hostname for the URL....removed for now
    #urls_for_visits = visits.map do |v|
    #url_for(:controller => 'visits', :action=>'index', :id=>v.customer)
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

  def upcoming_birthdays(recipients, from, to, customers)
    sending_to(recipients)
    @from = APP_CONFIG[:boxoffice_daemon_address] # override
    @subject << "Birthdays between #{from.strftime('%x')} and #{to.strftime('%x')}"
    @body.merge!( {:customers => customers} )
  end

  def sending_to(recipient)
    @recipients = recipient.kind_of?(Customer)? recipient.email : recipient.to_s
    @from = "AutoConfirm-#{Option.venue_shortname}@audience1st.com"
    @headers = {}
    @subject = "#{Option.venue} - "
    contact = if Option.help_email.blank?
              then "call #{Option.boxoffice_telephone}"
              else "email #{Option.help_email} or call #{Option.boxoffice_telephone}"
              end
    @body = {
      :email => Option.help_email,
      :phone => Option.boxoffice_telephone,
      :venue => Option.venue,
      :how_to_contact_us =>  <<EOS
If this isn't correct, or if you have questions about your order or
any problems using our Web site, PLEASE DO NOT REPLY to this email
as it was generated automatically.

Instead, please #{contact}.
Please include your name and login (as shown above), and if you're
experiencing technical problems, a description of the problem and the
type of browser and operating system you're using (Internet Explorer on
Windows, Safari or Firefox on Mac, etc.)

Thanks for your patronage!

#{Option.venue}
Powered by Audience1st
EOS
    }
  end
end


