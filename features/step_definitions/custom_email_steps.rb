module ScenarioHelpers
  module Email
    def get_mime_part(email, content_type)
      expect(email.body.parts.length).to be >= 1, "email doesn't appear to be MIME multipart"
      email.body.parts.find { |part| part.content_type =~ Regexp.new(content_type, Regexp::IGNORECASE) }
    end
    def get_plain_text_body(email)
      get_mime_part(email, 'text/plain').body.raw_source
    end
    def get_html_body(email)
      get_mime_part(email, 'text/html').body.raw_source
    end
  end
end

World(ScenarioHelpers::Email)

Then /^an email should be sent to( customer)? "(.*?)" containing "(.*)"$/ do |cust,recipient,link|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  @email = ActionMailer::Base.deliveries.first
  expect(@email).not_to be_nil
  expect(@email.to).to include(recipient)
  # emails are MIME multipart with both an HTML and text part.
  body = get_html_body(@email)
  expect(body).to include(link)
end

Then /^no email should be sent to( customer)? "(.*)"$/ do |cust,recipient|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  ActionMailer::Base.deliveries.any? { |e| e.to.include?(recipient) }.should be_falsey
end

# Needs magic_link implementation
Given /^customer "(.*)" clicks on "(.*)"$/ do |cust,link|
  visit link
end

Then /^a birthday email should be sent to( customer)? "(.*?)" containing "(.*)"$/ do |cust,recipient,link|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  Customer.notify_upcoming_birthdays()
  @email = ActionMailer::Base.deliveries.last
  expect(@email).not_to be_nil
  expect(@email.to).to include(recipient)
  body = get_html_body(@email)
  expect(body).to include(link)
end


