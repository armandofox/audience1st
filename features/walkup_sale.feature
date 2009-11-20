Feature: Walkup sale

  As a boxoffice worker
  I want to sell tickets to walkup customers
  So that we can maximize seat counts

  Background:
    Given a performance of "The Nerd" on October 1, 8:00pm
    And I am logged in as a box office worker

  Scenario: visit walkup sales page
    When I go to the walkup sales page
    Then I should see "The Nerd"
    And I should see 
