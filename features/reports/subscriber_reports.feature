@javascript
Feature: all subscribers/lapsed subscribers report

  As a boxoffice manager
  To track my subscribers
  I want to generate lists of subscribers for one or more seasons

Background: we have some subscribers  

  Given I am logged in as boxoffice manager
  And subscription vouchers for seasons 2009, 2010
  And the following subscribers exist:
  | customer | subscriptions |
  | Joe      |               |
  | Elaine   |     2009,2010 |
  | Diana    |          2010 |
  | Star     |          2009 |

Scenario:

  When I run the special report "All subscribers" with seasons: 2008,2009
  Then the report output should include only customers: Elaine, Star  

Scenario Outline: list all subscribers for specific season(s)

  When I run the special report "All subscribers" with seasons: <seasons>
  Then the report output should include only customers: <included>

Examples:

  |   seasons | included            |
  | 2008,2009 | Elaine, Star        |

Scenario Outline: list lapsed subscribers from 2009 to 2010

