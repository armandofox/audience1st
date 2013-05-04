Feature: accept retail purchases
  
  As an event manager or house manager
  So that I can record customer purchases that aren't tickets or donations
  I want to process a retail sale for a customer already in our database

Scenario: successful retail purchase

  Given I am logged in as administrator
  And I am acting on behalf of customer "Tom Foolery"
  When I visit the store page
  Then I should see "Retail purchase amount"
  When I fill in "Retail purchase amount" with "237.88"
  And I select "9999 General Fund" from "retail_account_code_id"
  And I fill in "Description of retail purchase" with "Auction item" 
  And I press "CONTINUE >>"
  Then I should be on the checkout page

Scenario: regular customers don't see retail option

  Given I am logged in as customer "Tom Foolery" 
  When I visit the store page
  Then I should not see "Retail purchase amount"
