Feature: Gift checkout

  As a patron
  So that I can gift tickets
  I want to checkout with gift tickets

Background:
  Given customer "Tom Foolery" exists with email "joe3@yahoo.com"
  And I am logged in as customer "Tom Foolery"
  And my gift order contains the following tickets:
    | show    | qty | type    | price | showdate             |
    | Chicago |   2 | General |  7.00 | May 15, 2010, 8:00pm |
  And the following customers exist:
    | first_name | last_name | email           | created_by_admin | street        | password | password_confirmation | city | state |   zip | day_phone    | last_login | updated_at | 
    | John       | Lennon    | john@lennon.com | false            | Imagine St.   | imagine  | imagine               | Berk | CA    | 99999 | 510-999-9999 | 2009-01-01 | 2009-01-01 |  
  
Scenario: Allow gift purchase if logged in and approved by box office manager
  Given the setting "allow gift tickets" is "true"
  And I go to the store page
  Then I should see "This order is a gift" 

Scenario: Prohibit gift purchase if logged in but unapproved by box office manager
  Given the setting "allow gift tickets" is "false"
  And I go to the store page
  Then I should not see "This order is a gift" 
    
Scenario: customer gifting to oneself should be unsuccessful
  Given I go to the shipping info page for customer "Tom Foolery"
  When I fill in the ".billing_info" fields with "Tom Foolery, 123 Fake St., Alameda, CA 94501, 510-999-9999, joe3@yahoo.com"
  And I proceed to checkout
  Then I should be on the shipping info page
  And I should see "Please enter a gift recipient email different from your own."

Scenario: display error message if recipient's last name does not match record on hand
  Given I go to the shipping info page for customer "Tom Foolery"
  When I fill in the ".billing_info" fields with "John Roake, Imagine St., Berkeley, CA 99999, 510-999-9999, john@lennon.com"
  And I proceed to checkout
  Then I should be on the shipping info page
  And I should see "The email address you entered for the gift recipient is already registered in the system, but the name you entered does not match our records. Please double-check that you entered the gift recipient's name and email address and try again"



