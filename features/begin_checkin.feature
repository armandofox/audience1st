Feature: begin checkin

  As a box office worker
  So that I can start checking in patrons
  I want to go to the checkin page for this show

  Scenario: visit checkin page
    Given a performance at 8:00pm
    And I am logged in as a box office worker
    And I follow "Box Office"
    Then I should be on the BoxOffice page

  Scenario: begin checkin
    Given I am on the BoxOffice page
    And I follow "Checkin"
    Then I should be on the checkin page

  Scenario: see how many seats are available


  
