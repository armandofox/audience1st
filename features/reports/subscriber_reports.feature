@javascript
Feature: all subscribers/lapsed subscribers report

  As a boxoffice manager
  To track my subscribers
  I want to generate lists of subscribers for one or more subscription vouchertypes

Background: we have some subscribers  


Scenario Outline: updated all_subscribers report by vouchertypes
  Given I am logged in as boxoffice manager
  And subscription vouchers for vouchertypes abc, first, second
  And the following subscribers exist:
  | customer         | subscriptions |
  | Joe Mallon       | abc, second   |
  | Patrick Tracy    | first, second |
  | Elaine Henninger | abc           |
  | Diana Moore      | first, abc    |
  | Star Valdez      | second        |

  When I run the special report "All subscribers" with vouchertypes: <vouchertypes>
  Then the report output should include only customers: <included>

Examples:
  | vouchertypes  | included                  |
  | abc           | Joe, Elaine, Diana        |
  | first         | Patrick, Diana            |
  | first, second | Joe, Patrick, Diana, Star |

Scenario Outline: list lapsed subscribers from 2009 to 2010

  Given I am logged in as boxoffice manager
  And subscription vouchers for seasons 2008, 2009, 2010
  And the following subscribers exist:
  | customer         | subscriptions |
  | Joe Mallon       |               |
  | Patrick Tracy    |          2008 |
  | Elaine Henninger |     2009,2010 |
  | Diana Moore      |          2010 |
  | Star Valdez      |          2009 |

  When I run the special report "Lapsed subscribers" to find <old> subscribers who have not renewed in <new>
  Then the report output should include only customers: <included>

Examples:
  |  old |  new | included |
  | 2009 | 2010 | Star     |
  | 2008 | 2010 | Patrick  |
  | 2008 | 2009 | Patrick  |
  | 2010 | 2010 |          |
