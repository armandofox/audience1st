Feature: Gift checkout

  As a customer
  So that I can gift tickets
  I want to checkout with gift tickets

Background:
  Given customer "Tom Foolery" exists with email "joe3@yahoo.com"
  And I am logged in as customer "Tom Foolery"
   
Scenario: Allow gift purchase if logged in and approved by box office manager
  Given the setting "allow gift tickets" is "true"
  And I go to the store page
  Then I should see "This order is a gift" 

Scenario: Prohibit gift purchase if logged in but unapproved by box office manager
  Given the setting "allow gift tickets" is "false"
  And I go to the store page
  Then I should not see "This order is a gift" 
    
