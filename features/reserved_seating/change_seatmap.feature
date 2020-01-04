Feature: change seatmap after seats have been sold for a show

  As a box office manager
  So I can keep up with changing theater configurations before the show goes up
  I want to be able to change a seatmap after tickets have been sold

Background: two seatmaps exist

  Given the following seat reservations for the March 2, 2010, 8:00pm performance:
    | first   | last    | vouchertype | seats |
    | Harvey  | Schmidt | General     | A1    |
    | Jerry   | Bock    | General     | A2    |
    | Tom     | Jones   | General     | B1    |
    | Sheldon | Harnick | General     | B2    |
  And I am logged in as boxoffice manager
  
Scenario: All existing patrons can be accommodated in new seatmap

  Given a seatmap "Alternate" with seats B2,B1,A2,A1,C2,C3
  When I try to change the seatmap for that performance to "Alternate"
  Then I should be on the show details page for "Show"
  And I should see "Changes saved"
  And that performance should use the "Alternate" seatmap

Scenario: Some patrons must be reassigned to new seats

  Given a seatmap "Alternate" with seats A1,B2
  When I try to change the seatmap for that performance to "Alternate"
  Then I should be on the edit showdate page for that performance
  And I should see "Seat map cannot be changed because the following patrons have reserved seats that don't exist in the new seat map"
  And I should see "Jerry Bock (A2)"
  And I should see "Tom Jones (B1)"
  
Scenario: cannot change general admission showdate to use seatmap if any tickets have been sold

Scenario: can change general admission showdate to reserved seating if no tickets have been sold

  
  
