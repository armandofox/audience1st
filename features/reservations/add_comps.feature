Feature: add comps and reserve for a show

  As a box office worker
  So I can comp my best customers
  I want to add comp tickets for a particular performance

Background: logged in as admin and shows are available

  Given I am logged in as boxoffice manager
  And I am acting on behalf of customer "Tom Foolery"
  And 10 "Comp" comps are available for "Macbeth" on "April 20, 2010, 8pm"
  And I am on the add comps page

Scenario: add comps to performance with seats available

  When I select "Comp (2010)" from "What type:"
  And  I fill in "How many:" with "2"
  And  I fill in "Optional comments:" with "Courtesy Comp"
  And  I select "Macbeth - Tuesday, Apr 20, 8:00 PM (10 left)" from "Reserve for:"
  And  I press "Add Vouchers"
  Then customer "Tom Foolery" should have an order with comment "Courtesy Comp" containing the following tickets:
  | qty | type | showdate       |
  |   2 | Comp | Apr 20, 8:00pm |

Scenario: add comps to sold-out performance

  
  
