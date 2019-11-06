Feature: boxoffice agent can add reserved-seat comps

Background: show with reserved seating

  Given a performance of "Chicago" on March 1, 2010, 8:00pm
  And that performance has reserved seating
  And 4 "Comp" comps are available for "Chicago" on "March 1, 2010, 8:00pm"
  And I am logged in as boxoffice manager
  And I am on the add comps page for customer "Joe Mallon"

Scenario: add comps and reserve specific seats

  When I select "Comp (2010)" from "What type:"
  Then I should see the seatmap  

Scenario: cannot add comps without specifying seats  
