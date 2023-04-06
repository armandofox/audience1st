@javascript
Feature: edit house seats per performance

  As a boxoffice manager
  So that I can adjust house seats fine-grained
  I want to add or remove house seats on an existing performance that may have reservations

  Background: reserved seating show with some designated house seats

    Given a performance of "The Nerd" on March 2, 2010, 8pm
    And that performance has reserved seating
    And the following seats are occupied for that performance: A1,B2
    And the following are house seats for that performance: A2,B2
    And I am logged in as boxoffice manager
    And I visit the edit showdate page for that performance

  Scenario: add house seats when some house seats are already occupied

    When I choose seat "Reserved-B1"
    Then the "House seats" field should contain "A2, B1"
    And the "Occupied house seats" field should contain "B2"
    When I press "Save Changes"
    Then that performance's house seats should be: A1, B1, B2

    
