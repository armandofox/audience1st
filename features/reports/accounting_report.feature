@wip
Feature: run accounting report

  As the financial manager
  So that I can reconcile my bank statements
  I want to see detailed accounting reports

Background: 

  Given I am logged in as staff

Scenario: View donations by date and account code

  Given the following donations:
    |       date | amount | fund          | donor       | payment     |
    | 2011-03-10 |  25.00 | 2222 Donation | Tom Foolery | credit card |
    | 2011-03-12 |     20 | 3333 Capital  | Tom Foolery | cash        |
    | 2011-03-12 |     15 | 2222 Donation | Joe Mallon  | credit_card |
  When I run the accounting report from "2011-03/10 10:00am" to "2011-03-12 11:45PM"

  
