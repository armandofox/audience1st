Feature: display printable door list

  As a box office worker
  So that I can check in customers in case the Internet is unavailable
  I want to generate a printable door list

Scenario: generate door list

  Given a performance of "Chicago" on April 15, 2010, 8:00pm
  And customer Joe Smith has 2 "General" tickets
  And customer Joe Smith has 3 "Senior" tickets
  And customer Bob Jones has 8 "General" tickets
  And  I am logged in as boxoffice manager
  
  When I go to the door list page for April 15, 2010, 8:00pm
  Then I should see "13 total reservations"
  
