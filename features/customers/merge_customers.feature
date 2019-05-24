Feature: merge customers

  As a boxoffice manager
  So that I can keep my database tidy
  I want to merge redundant customer records

Background:

  Given the following customers exist:
    | first_name | last_name | email          | created_by_admin | street        | password | password_confirmation | city | state |   zip | last_login          | updated_at |
    | MaryJane   | Weigandt  | mjw@mail.com   | true             | 11 Main St    |          |                       | Oak  | CA    | 99994 | 2011-01-03 03:00:00 | 2011-01-01 |
    | Janey      | Weigandt  | janey@mail.com | false            | 11 Main St #1 | blurgle  | blurgle               | Oak  | CA    | 99949 | 2010-01-01 04:00:00 | 2010-01-01 |
  And the following donations:
   | amount |       date | donor             | fund         |
   | $35.00 | 2009-01-01 | Janey Weigandt    | General Fund |
   | $12.00 | 2009-05-01 | MaryJane Weigandt | General Fund |
  And I am logged in as boxoffice
  And I select customers "MaryJane Weigandt" and "Janey Weigandt" for merging

Scenario: auto merge 
  
  When I press "Auto Merge"
  Then customer "Janey Weigandt" should not exist
  And customer "MaryJane Weigandt" should have the following attributes:
   | attribute | value        |
   | street    | 11 Main St   |
   | zip       | 99994        |
   | email     | mjw@mail.com |
  And customer "MaryJane Weigandt" should have a donation of $35.00 to "General Fund"
  And customer "MaryJane Weigandt" should have a donation of $12.00 to "General Fund"

Scenario: manual merge
  # MaryJane appears in column 0 (left), Janey in column 1 (right)
  When I press "Manual Merge"
  And I choose "first_name_1"
  And I choose "email_1"
  And I choose "street_0"
  And I choose "zip_1"
  And I press "Merge Records"
  Then I should see /Transferred .+ to customer/
  And customer "MaryJane Weigandt" should not exist
  And customer "Janey Weigandt" should have the following attributes:
   | attribute  | value               |
   | last_login | 2011-01-03 03:00:00 |
   | zip        | 99949               |
   | email      | janey@mail.com      |
   | street     | 11 Main St          |

Scenario: cannot merge Admins

  When I select customers "Super Administrator" and "Janey Weigandt" for merging
  And I press "Auto Merge"
  Then I should see "super admins cannot be merged"
  And customer "Janey Weigandt" should exist
  And customer "Super Administrator" should exist
