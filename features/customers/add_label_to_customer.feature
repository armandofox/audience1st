Feature: Box office manager can associate labels with customers

  As a box office manager
  So that I can mark which customers are interested in volunteering
  I want to label a customer with "Volunteer"

Background:

  Given the label "Volunteer" exists
  And I am logged in as staff

Scenario: add label to customer

  When I go to the edit contact info page for customer "Tom Foolery"
  Then I should see "Contact Info for Tom Foolery"
  And I should see "Labels" within "#adminPrefs"
  And I should see "Volunteer" within "#current_labels"

  When I check "Volunteer"
  And I press "Save Changes"
  Then I should see "Contact information for Tom Foolery successfully updated"
  And customer "Tom Foolery" should have label "Volunteer"

Scenario: remove label from customer

  Given customer "Tom Foolery" has label "Volunteer"
  When I go to the edit contact info page for customer "Tom Foolery"
  Then the "Volunteer" checkbox should be checked

  When I uncheck "Volunteer"
  And I press "Save Changes"
  Then I should see "Contact information for Tom Foolery successfully updated"
  And customer "Tom Foolery" should not have label "Volunteer"
    
    

