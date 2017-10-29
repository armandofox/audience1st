Feature: search for customer by anything

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And I am on the list of customers page

Scenario: Show details for all matches

  Given the following customers exist: Alex Fox, Armando Fox, Bob Bag
  Given customer "Dianne Feinstein" whose address street is: "123 Fox Hill Road"
  When I search for "Fox"  
  Then table "#customers" should include:
  | First name | Last name |
  | Alex       | Fox       |
  | Armando    | Fox       |
  | Dianne     | Feinstein |
  But table "#customers" should not include:
  | First name | Last name |
  | Bob        | Bag       |

Scenario: Show details for all matches

  Given the following customers exist: Alex Fox, Armando Fox, Bob Bag
  Given customer "Barbara Boxer" whose address street is: "200 Alexander Ave."
  When I search for "fox alex"
  Then table "#customers" should include:
  | First name | Last name |
  | Alex       | Fox       |
  But table "#customers" should not include:
  | First name | Last name |
  | Barbara    | Boxer     |
  
  When I search for "alex"
  Then table "#customers" should include:
  | First name | Last name |
  | Alex       | Fox       |
  | Barbara    | Boxer     |
