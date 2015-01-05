Feature: run accounting report

  As the financial manager
  So that I can reconcile my bank statements
  I want to see detailed accounting reports

Background: 

  Given I am logged in as staff
  And the following Purchasemethods exist:
    | description | shortdesc | nonrevenue |
    | Credit Card | box_cc    | nil        |
    | Cash        | box_cash  | nil        |

Scenario: View donations by date and account code

  Given the following donations:
    | date    | amount | fund          | donor       | payment     |
    | 3/10/11 |  25.00 | 2222 Donation | Tom Foolery | credit card |
    | 3/12/11 |     20 | 3333 Capital  | Tom Foolery | cash        |
    | 3/12/11 |     15 | 2222 Donation | Joe Mallon  | credit_card |
  When I run the accounting report from "3/10/11 10:00am" to "3/12/11 11:45PM"

  
