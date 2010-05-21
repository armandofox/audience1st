Feature: Import customer list

  As a box office manager
  So that I can centralize my patron mailinglist info and historical
    info in one place
  I want to import a list of customers

Scenario: Begin import

  Given I am logged in as the administrator
  And I follow "Admin"
  Then I should be on the Admin:Settings page
  When I follow "Import"
  Then I should be on the Admin:Import page
  And I should see "Import customer list..."

Scenario: Stage spreadsheet for upload
  
  Given I am logged in as the administrator      
  And I go to the Admin:Import page
  
