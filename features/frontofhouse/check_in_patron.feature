@javascript
Feature: Check in a patron

  As a box office worker
  So that I can track how many people have arrived for the show
  I want to check in an arriving patron

Background:

  Given a performance of "Chicago" on April 15, 2010, 8:00pm
  And customer Joe Smith has 2 "General" tickets
  And customer Bob Jones has 3 "Senior" tickets
  And  I am logged in as boxoffice
  And  I am on the checkin page for April 15, 2010, 8:00pm

Scenario: correct checkin information appears

  And I should see a row "|Smith|Joe|General||1 2" within "table[@id='checkin']"
  And I should see a row "|Jones|Bob|Senior||1 2 3" within "table[@id='checkin']"

Scenario: check in everyone in small party
