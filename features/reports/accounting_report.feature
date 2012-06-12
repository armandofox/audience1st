Feature: run accounting report

  As the financial manager
  So that I can reconcile my bank statements
  I want to see detailed accounting reports

Background: 

  Given I am logged in as staff
  And the following account codes exist:
    | name     | code | description                   |
    | Tickets  | 1111 | Ticket revenue                |
    | Donation | 2222 | General donations             |
    | Capital  | 3333 | Donations to capital campaign |
  And the following purchasemethods exist:
    | description | shortdesc | nonrevenue |
    | Credit Card | box_cc    | nil        |
    | Cash        | box_cash  | nil        |

Scenario: View breakdown of donations by date and account code

  Given the following donations exist:
    | date            | amount | account_code  | customer_id | purchasemethod          |
    | 3/10/11 11:00am |  25.00 | name:Donation |          77 | description:Credit Card |
    | 3/12/11 1:00pm  |     20 | name:Donation |          77 | description:Cash        |
    | 3/12/11 1:15PM  |     15 | name:Capital  |          78 | description:Credit Card |
  When I run the accounting report from "3/10/11 10:00am" to "3/12/11 11:45PM"

  
