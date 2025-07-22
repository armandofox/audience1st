Feature: setup recurring donation

  As an eager patron
  So that I can support the theater without thinking about it every month
  I want to set up a monthly recurring donation of a fixed amount indefinitely

  Background: patron has an account and is logged in

    Given I am logged in as customer "Tom Foolery"

  @stubs_successful_recurring_payment
  @suspended
  Scenario: successfully create new recurring donation

    When I visit the recurring donations setup page
    And I fill in "Amount" with "25"
    And I press "Proceed to Payment"
    

    
