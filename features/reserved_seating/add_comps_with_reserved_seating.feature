@javascript
Feature: boxoffice agent can add reserved-seat comps

  As a box office agent
  So that I can comp customers to reserved-seating shows
  I want to add comps for a specific showdate with reserved seats

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
  And I select "Comp (2010)" from "What type:"
  And I select the "March 2, 2:00pm" performance of "Chicago" from "Reserve for:"
  Then I should see the seatmap  
  When I choose seats B1,B2
  Then I should see "B1" in the list of selected seats
  When I press "Add Vouchers"
  Then customer "Joe Mallon" should have seat B1 for the March 2, 2010, 2pm performance of "Chicago"

Scenario: selecting general admission show should make seatmap disappear

  When I fill in "How many:" with "2"
  And I select "Comp (2010)" from "What type:"
  And I select the "March 2, 2pm" performance of "Chicago" from "Reserve for:"
  Then I should see the seatmap  
  When I select the "March 1, 8pm" performance of "Chicago" from "Reserve for:"
  Then I should not see the seatmap
  When I fill in "How many:" with "2"
  And I press "Add Vouchers"
  Then customer "Joe Mallon" should have 2 "Comp" tickets for "Chicago" on Mar 1, 2010, 8pm
