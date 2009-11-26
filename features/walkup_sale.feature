Feature: Open walkup sales

  As a boxoffice worker
  I want to sell tickets to walkup customers
  So that we can maximize seat counts

  Background:
    Given a performance of "The Nerd" on October 1, 8:00pm
    And 10 General vouchers costing $11.00 are available for this performance
    And today is October 1, 7:00pm
    And I am logged in as a box office worker
    And I go to the walkup sales page

  Scenario: visit walkup sales page
    I should see "The Nerd"
    And I should see /Oct\s+1,\s+8:00\s+PM/
    And I should see 

  Scenario: select vouchers
  
