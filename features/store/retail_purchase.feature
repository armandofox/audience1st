Feature: accept retail purchases
  
  As an event manager or house manager
  So that I can record customer purchases that aren't tickets or donations
  I want to process a retail sale for a customer already in our database

Background: logged in as administrator acting on behalf of a patron

  Given the setting "allow gift tickets" is "true"
  And I am logged in as administrator
  When I visit the store page for customer "Tom Foolery"
  Then I should see "Retail purchase amount"
  When I fill in "Retail purchase amount" with "237.88"
  And I select "0000 General Fund" from "retail_account_code_id"

Scenario: successful retail purchase

  When I fill in "Description of retail purchase" with "Auction item" 
  And I proceed to checkout
  Then I should be on the checkout page for customer "Tom Foolery"
  And I should see "Auction item"
  When the order is placed successfully
  Then customer "Tom Foolery" should have the following items:
  | type       | amount | comments     | account_code |
  | RetailItem | 237.88 | Auction item |         0000 |
  And I should be on the order confirmation page for customer "Tom Foolery"
  And I should see "Auction item $237.88"

Scenario: gift purchase cannot include retail item

  When I fill in "Description of retail purchase" with "Auction item" 
  And I check "gift"
  And I proceed to checkout
  Then I should be on the store page for customer "Tom Foolery"
  And I should see "Retail items can't be included in a gift order"

Scenario: invalid retail purchase info returns you to store page

  When I proceed to checkout
  Then I should be on the store page for customer "Tom Foolery"
  And I should see "Comments or description can't be blank"

Scenario: regular customers don't see retail option

  Given I am logged in as customer "Tom Foolery" 
  When I visit the store page
  Then I should not see "Retail purchase amount"
