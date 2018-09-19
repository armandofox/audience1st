Feature: Customer can enter birthday

  As a customer 
  So I can get freebies on my birthday
  I want to be able to add my birthday to my profile

Background: 

  Given I am logged in as customer "Tom Foolery" 

Scenario: Add birthday to profile

  When I visit the edit contact info page
  Then nothing should be selected in the "customer_birthday_2i" menu
  When I select "May 12" as the "Birthday (optional)" month and day
  And I press "Save Changes"
  Then customer "Tom Foolery" should have a birthday of "May 12"

Scenario: Birthday appears correctly in profile

  Given my birthday is set to "June 3"
  When I visit the edit contact info page
  Then "June 3" should be selected as the "Birthday (optional)" date

Scenario: Leave birthday blank

  When I visit the edit contact info page
  And I press "Save Changes" 
  And I visit the edit contact info page
  Then nothing should be selected in the "customer_birthday_2i" menu
  And  nothing should be selected in the "customer_birthday_3i" menu
