class ChangeSendgridDomainToSenderDomain < ActiveRecord::Migration
  def change
    o = Option.first
    o.sendgrid_domain = 'mail.audience1st.com'
    o.save!
    rename_column 'options', 'sendgrid_domain', 'sender_domain'
    # match current mailgun configuration
  end
end
