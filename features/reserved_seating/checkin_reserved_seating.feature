Feature: reservation checkin for reserved seating show

  As a front of house worker
  So that I can keep track of which specific seats I've handed out boarding cards for
  I want to check in a party by selecting specific seats

Background: reserved seating performance

  Given a performance of "Chicago" on March 2, 2010, 8:00pm
  And that performance has reserved seating
  And the following seat reservations for the March 2, 2010, 8:00pm performance:
    | first  | last    | vouchertype | seats    |
    | Harvey | Schmidt | General     | A1,B1,A2 |
    | Tom    | Jones   | General     | B2       |
  And I am logged in as boxoffice

Scenario: with reserved seating, check in one seat at a time

  Given I am on the checkin page for March 2, 2010, 8:00pm
  Then I should see a row "|Schmidt|Harvey|General||A1 B1 A2" within "table[@id='checkin']"
  Then I should see a row "|Jones|Tom|General||B2" within "table[@id='checkin']"

Scenario: un-check-in all
