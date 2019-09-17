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


Scenario: Create new seatmap from valid CSV

  When I upload the seatmap "valid_seatmap.csv"
