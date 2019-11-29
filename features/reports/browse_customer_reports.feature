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
  And I choose "Estimate number of matches"
  And I press "Run Report"
  Then I should see an alert matching /<alert>/

  Examples: customer report fields
    | report_type                         | alert                                               |
    | Lapsed subscribers                  | You must specify at least one type of voucher       |
    | Attendance at specific performances | Please select a valid show date                     |
    | New customers                       | 0 matches                                           |
    | Subscriber open vouchers            | Please specify one or more subscriber voucher types |
    | Attendance by show                  | Please specify one or more productions              |
    | Donor appeal                        | 0 matches                                           |
    | All subscribers                     | Please specify one or more subscriber voucher types |

