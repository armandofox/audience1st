Feature: giving comps as walkup sales

  As a boxoffice manager
  To better control who does anonymous comping
  I want to allow only the boxoffice manager to do walkup comps

Background:  
  Given a show "Chicago" with the following tickets available:
  | qty | type    | price  | showdate              |
  |   2 | General | $15.00 | April 7, 2010, 8:00pm |
  |   1 | Comp    | $0.00  | April 7, 2010, 8:00pm |

Scenario: Box office manager can give walkup comps
  
  Given I am logged in as boxoffice manager
  And I go to to the walkup sales page for April 7, 2010, 8:00pm
  Then I should see "General" within "#walkup_tickets"
  And I should see "Comp" within "#walkup_tickets"

Scenario: Box office worker cannot give walkup comps

  Given I am logged in as boxoffice
  And I go to to the walkup sales page for April 7, 2010, 8:00pm
  Then I should see "General" within "#walkup_tickets"
  And I should see "Comp (1 left) (Box office manager only)" within "#walkup_tickets"
  And I should see "What's this?" within "#walkup_tickets"
