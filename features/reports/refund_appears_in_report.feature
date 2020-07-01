@stubs_successful_refund
Feature: refund appears as separate item in reports

  As a box office manager
  So that I can clearly track refunds of purchase transactions
  I want to see both the original purchase and the refund in the revenue details report

  Background: items purchased and then refunded

    Given I am logged in as boxoffice manager
    And a "SeasonSub" subscription available to anyone for $75.00
    And the following orders have been placed:
      |       date | customer    | item1        | item2        | payment     |
      | 2009-12-21 | Tom Foolery | 2x SeasonSub | $20 donation | credit card |
    And I refund item 1 of that order
    Then show me the page
    
      
    
