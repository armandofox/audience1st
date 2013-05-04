Feature: accept retail purchases
  
  As an event manager or house manager
  So that I can record customer purchases that aren't tickets or donations
  I want to process a retail sale for a customer already in our database

Scenario: successful retail purchase

  Given I am logged in as administrator
  And I am acting on behalf of customer "Tom Foolery"
  When I visit the store page
  Then I should see "Retail Purchase Amount"
  

Scenario: regular customers don't see retail option

  Given I am logged in as customer "Tom Foolery" 
  When I visit the store page
  Then I should not see "Retail Purchase Amount"
