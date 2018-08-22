@stubs_successful_credit_card_payment
Feature: Guest checkout

  As a box office manager
  So that I can entice people to buy tickets
  I want to enable guest checkout, so patrons just give email & billing

  Background: 

  Given a show "The Nerd" with the following tickets available:
  | qty | type    | price  | showdate                |
  |   3 | General | $15.00 | October 1, 2010, 7:00pm |
  And   I go to the store page

  Scenario: guest checkout for single-ticket purchases

  Scenario: multiple guest checkouts to same email credit tickets to same account
      
  Scenario: no guest checkout allowed for subscription purchases or camps

    
  






   
