Feature: Import customer list

  As a box office manager
  So that I can centralize my patron mailinglist info and historical
    info in one place
  I want to import a list of customers

Background:
  Given I am logged in as the administrator
  And I follow "Admin"
  Then I should be on the Admin:Settings page
  When I follow "Import"
  Then I should be on the Admin:Import page
  And I should see "What do you want to import"
  And the "import_type" menu should contain "Customer/mailing list"

Scenario: Upload customer import list
  
  When I select "Customer/mailing list" from "import_type"
  And I upload customer import list "list_with_2_customers.csv"
  Then I should see "A preview of what will be imported is below"


  
