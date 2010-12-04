@ip
Feature: add label to customer

  As a staff user
  So that I can mark which customers are interested in volunteering
  I want to label a customer with "Volunteer"

Background:

  Given the label "Volunteer" exists
  And I am logged in as staff
  And I am on the edit contact info page for "tom"
  Then I should see "Labels" within "fieldset#admin_form"
  And I should see "Volunteer" within "div#current_labels"

Scenario: add label to customer

  When I check "Volunteer"
  And I press "Save Changes"
  Then customer "tom" should have label "Volunteer"
  
  
    

