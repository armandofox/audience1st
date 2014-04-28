Feature: add comps and reserve for a show

  As a box office worker
  So I can comp my best customers
  I want to add comp tickets for a particular performance

Background: logged in as admin and shows are available

  Given I am logged in as boxoffice manager
  And I am acting on behalf of customer "Tom Foolery"
  And 10 "Comp" comps are available for "Macbeth" on "April 20, 2013, 8pm"
  And I am on the add comps page

Scenario: add comps to performance with seats available

  When I fill in "How many:" with "2"
  And  I select "April 20, 2013,  8:00pm" from "showdate_id"
  And  I fill in "Optional comments:" with "Courtesy Comp"
  And  I press "Add Vouchers"

Scenario: add comps to sold-out performance

  
  
