@selenium
Feature: browse customer reports

  As an administrator
  So that I can understand all the kinds of customer reports I can run
  I want to browse different customer report types

Background:

  Given I am logged in as administrator
  And I visit the reports page

Scenario Outline: browse reports

  When I select <report type> from "report_name"
  Then I should see "<a_report_option>"
  When I press 'Estimate number of matches'
  Then I should see /[0-9]+ matches/

  Examples: customer report fields
    | report type                   | a_report_option                                       |
    | New customers                 | List customers who were added to the database         |
    | Lapsed subscribers            | Find patrons who purchased                            |
    | Subscriber open vouchers      | List customers who have open (unreserved) vouchers    |
    | Donor appeal                  | Donors who have made at least one donation of         |
    | Attendance by show            | List customers who attended                           |
    | Attendance at specific performances | List customers attending this specific          |

