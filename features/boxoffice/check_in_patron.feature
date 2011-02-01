Feature: Check in a patron

  As a box office worker
  So that I can track how many people have arrived for the show
  I want to check in an arriving patron

Background:

  Given a performance of "Chicago" on April 15, 2010, 8:00pm
  And customer Joe Smith has 2 "General" tickets
  And customer Joe Smith has 3 "Senior" tickets
  And customer Bob Jones has 8 "General" tickets
  And  I am logged in as boxoffice
  And  I am on the checkin page for April 15, 2010, 8:00pm
  Then I should see "April 15, 2010, 8:00pm"

Scenario: check in everyone in small party

