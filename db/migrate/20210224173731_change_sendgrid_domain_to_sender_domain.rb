class ChangeSendgridDomainToSenderDomain < ActiveRecord::Migration
  def change
    o = Option.first
    if (o)
      o.sendgrid_domain = 'mail.audience1st.com'
      o.save!
    end
    rename_column 'options', 'sendgrid_domain', 'sender_domain'
    # match current mailgun configuration
  end
end
