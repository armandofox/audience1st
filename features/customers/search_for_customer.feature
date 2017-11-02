Feature: search for customer by anything

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And I am on the list of customers page
  And the following Customers exist:
    | first_name | last_name | email          | street        | city | state |
    | Alex       | Fox       | afox@mail.com  | 11 Main St #1 |  SAF | CA    |
    | Armando    | Fox       | arfox@mail.com | 11 Main St    |  SAF | CA    |
    | Bilbo      | Baggins   | BB@email.com   | 123 Fox Hill  |  SAF | CA    |
    | Bob        | Bag       | BBB@email.com  | 23 Alexander  |  SAF | CA    |

  Scenario: Show details for all matches


  When I search for "Fox"
  Then table "#customers" should include:
  | First name | Last name |
  | Alex       | Fox       |
  | Armando    | Fox       |
  | Bilbo      | Baggins   |
  But table "#customers" should not include:
  | First name | Last name |
  | Bob        | Bag       |

Scenario: Show details for all matches

  When I search for "fox alex"
  Then table "#customers" should include:
  | First name | Last name |
  | Alex       | Fox       |
  But table "#customers" should not include:
  | First name | Last name |
  | Bob        | Bag       |
  
  When I search for "alex"
  Then table "#customers" should include:
  | First name | Last name |
  | Alex       | Fox       |
  | Bob        | Bag       |
