@javascript
Feature: boxoffice agent can add reserved-seat comps

Background: show with some reserved seating and some general admission performances

  Given a performance of "Chicago" on March 1, 2010, 8:00pm
  Given a performance of "Chicago" on March 2, 2010, 2:00pm
  And that performance has reserved seating
  And 4 "Comp" comps are available for "Chicago" on "March 1, 2010, 8:00pm"
  And 1 "Comp" comps are available for "Chicago" on "March 2, 2010, 2:00pm"
  And I am logged in as boxoffice manager
  And I am on the add comps page for customer "Joe Mallon"

Scenario: add comps and reserve specific seats

  When I fill in "How many:" with "1"
  When I select "Comp (2010)" from "What type:"
  And I select the "March 2, 2:00pm" performance of "Chicago" from "Reserve for:"
  Then I should see the seatmap  
  When I choose seats B1,B2
  

Scenario: cannot add comps without specifying seats  
