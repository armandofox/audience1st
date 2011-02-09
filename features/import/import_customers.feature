Feature: Import customer list

  As a box office manager
  So that I can centralize my patron mailinglist info and historical
    info in one place
  I want to import a list of customers

Background:

  Given I am logged in as the administrator
  And I go to the Admin:Import page
  Then I should see "What do you want to import"
  And I should see "Customer/mailing list" within "select[id=import_type]"

Scenario: Upload customer import list
  
  When I select "Customer/mailing list" from "import_type"
  And I upload customer import list "list_with_2_customers.csv"
  Then I should see "A preview of what will be imported is below"


  
