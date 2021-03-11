Feature: update customer information

  As a box office agent
  So that I can get to know my customers and keep their info timely
  I want to update information about customers

Scenario: change staff-only comment, labels, blacklist; don't email

  Given I am logged in as boxoffice manager
  And I visit the edit contact info page for customer "Armando Fox"
  When I fill in "Staff Comments" with "Lush"
  And I check "dont_send_email"
  And I check "customer_blacklist"
  And I check "customer_e_blacklist"
  And I press "Save Changes"
  Then customer "Armando Fox" should have the following attributes:
  | attribute   | value |
  | comments    | Lush  |
  | e_blacklist | true  |
  | blacklist   | true  |
  And no email should be sent to customer "Armando Fox"

Scenario: superadmin can change customer role

  Given I am logged in as administrator  
  And I visit the edit contact info page for customer "Armando Fox"
  And I select "Staff" from "Role"
  And I press "Save Changes"
  Then customer "Armando Fox" should have the "staff" role

Scenario: customer can change their own info

  Given I am logged in as customer "Armando Fox"
  And I visit the edit contact info page for customer "Armando Fox"
  And I fill in the following:
    | First name | Alex        |
    | Street     | 233 E 69 St |
  And I uncheck "customer_e_blacklist"
  And I press "Save Changes"
  Then customer "Alex Fox" should have the following attributes:
  | attribute   | value       |
  | e_blacklist | false       |
  | street      | 233 E 69 St |
