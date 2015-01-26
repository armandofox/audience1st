Feature: admin can act on behalf of customer

  As an admin or staff
  So that I can process orders for customers
  I want to act on behalf of a customer

Background:

  Given the following customers exist: Jesus Jones, Martha Graham

Scenario: staff can act on behalf of customer

  Given I am logged in as boxoffice
  When I switch to customer "Jesus Jones"
  Then I should be acting on behalf of customer "Jesus Jones"
  When I switch to customer "Martha Graham"
  Then I should be acting on behalf of customer "Martha Graham"

Scenario: logged in customer can edit himself


  
Scenario: logged in customer cannot show or edit another customer

