Feature: search for customer by anything

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And I am on the list of customers page

Scenario: search by last name

  Given the following customers exist: Frodo Baggins, Bilbo Baggins, Bob Bag
  When I search any field for "Baggins"  
  Then table "#customers" should include:
  | First name | Last name |
  | Frodo      | Baggins   |
  | Bilbo      | Baggins   |
  But table "#customers" should not include:
  | First name | Last name |
  | Bob        | Bag       |

Scenario: partial match last name

  Given the following customers exist: Frodo Baggins, Bilbo Baggins, Bob Bag
  When I search any field for "Bag"  
  Then table "#customers" should include:
  | First name | Last name |
  | Frodo      | Baggins   |
  | Bilbo      | Baggins   |
  | Bob        | Bag       |
