Feature: Boxoffice can edit seatmap

  As a boxoffice manager
  So I can manage different theater configurations
  I want to manage seatmaps by uploading and downloading CSV files and background images

Background:

  Given I am logged in as boxoffice manager
  And the seatmap "Default" exists
  And I am on the seatmap editor page
  
Scenario: download CSV of existing seatmap

  When I follow "Download CSV" for the "Default" seatmap
  Then a CSV file should be downloaded containing:
  | A1 |     | A2 |    |
  |    | B1+ |    | B2 |

@javascript
Scenario: edit existing seatmap image URL and name

  When I follow "Edit" for the "Default" seatmap
  When I fill in the "Default" seatmap image URL as "http://foo.com" and name as "Simple"
  And I press "Save" for the "Default" seatmap
  Then that seatmap should have image URL "http://foo.com" and name "Simple"
  And I should be on the seatmap editor page
  
Scenario: Create new seatmap from valid CSV

  When I fill in "New" and "http://foo.com/x.jpg" as the name and image for a new seatmap
  And the URI "http://foo.com/x.jpg" is readable
  And I upload the seatmap "valid_seatmap.csv"
  Then I should be on the seatmap editor page
  And a seatmap named "New" should exist
  When I follow "Download CSV" for the "New" seatmap
  Then a CSV file should be downloaded containing:
    | A1 |    | B1+ |
    |    | A2 | B2  |

Scenario: Create new seatmap from invalid CSV
  
  When I fill in "New" and "http://foo.com/x.jpg" as the name and image for a new seatmap
  And the URI "http://foo.com/x.jpg" is readable
  And I upload the seatmap "blank_seatmap.csv"
  Then I should see "Seatmap CSV has errors"

Scenario: Delete seatmap

  When I press "Delete" for the "Default" seatmap
  Then I should see "Seatmap 'Default' deleted."
  And a seatmap named "Default" should not exist
  
