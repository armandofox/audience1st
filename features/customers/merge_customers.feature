Feature: merge customers

  As a boxoffice manager
  So that I can keep my database tidy
  I want to merge redundant customer records

Background:

  Given the following Customers exist:
   | first_name | last_name | email          | created_by_admin | street        | city | state |   zip | last_login | updated_at |
   | MaryJane   | Weigandt  | mjw@mail.com   | true             | 11 Main St    | Oak  | CA    | 99994 | 2011-01-03 | 2011-01-01 |
   | Janey      | Weigandt  | janey@mail.com | false            | 11 Main St #1 | Oak  | CA    | 99949 | 2010-01-01 | 2010-01-01 |
  And the following donations:
   | amount |       date | donor             | fund    |
   |  35.00 | 2009-01-01 | Janey Weigandt    | General |
   |  12.00 | 2009-05-01 | MaryJane Weigandt | General |
  And I am logged in as boxoffice

Scenario: auto merge 
  
  When I select customers "MaryJane Weigandt" and "Janey Weigandt" for merging
  And I press "Auto Merge"
  Then customer "Janey Weigandt" should not exist
  And customer "MaryJane Weigandt" should have the following attributes:
   | attribute | value        |
   | street    | 11 Main St   |
   | zip       | 99994        |
   | email     | mjw@mail.com |
  And customer "MaryJane Weigandt" should have a donation of $35.00 to "General"
  And customer "MaryJane Weigandt" should have a donation of $12.00 to "General"

Scenario: forget customer



  
