@javascript
Feature: browse customer reports

  As an administrator
  So that I can understand all the kinds of customer reports I can run
  I want to browse different customer report types

Background:

  Given I am logged in as administrator
  And I visit the reports page

Scenario Outline: browse reports

  When I select "<report_type>" from "special_report_name"
  Then I should see "<a_report_option>"
  When I choose "Estimate number of matches"
  And I press "Run Report"
  Then I should see an alert matching /[0-9]+ matches/

  Examples: customer report fields
    | report_type                         | a_report_option                                    |
    | Lapsed subscribers                  | Find patrons who purchased                         |
    | Attendance at specific performances | List customers attending this specific             |
    | New customers                       | List customers who were added to the database      |
    | Subscriber open vouchers            | List customers who have open (unreserved) vouchers |
    | Attendance by show                  | List customers who attended                        |
    | Donor appeal                        | Donors who have made at least one donation of      |

