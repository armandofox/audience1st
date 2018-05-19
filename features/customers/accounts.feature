Feature: Creating an account

  As an anonymous customer
  I want to be able to create an account
  So that I can be one of the cool kids

  Background: 

    Given I am not logged in
    And I am on the new customer page
    And I fill in the following:
      | First name       | John          |
      | Last name        | Doe           |
      | Street           | 123 Fake St   |
      | City             | San Francisco |
      | State            | CA            |
      | Zip              | 94131         |
      | Preferred phone  | 415-555-2222  |
    
  Scenario: New customer can create an account

    When I fill in the following:
      | Email            | john@doe.com  |
      | Password         | johndoe       |
      | Confirm Password | johndoe       |
    And I press "Create My Account"
    Then I should be on the home page for customer "John Doe"  
    And I should see "Welcome, John"
    And an email should be sent to "john@doe.com" matching "password" with "Your new password is:\s*(johndoe)"

  Scenario: New customer cannot create account without providing email address

    When I fill in the following:
      | Password         | johndoe       |
      | Confirm Password | johndoe       |
    And I press "Create My Account"
    Then account creation should fail with "Email is invalid"

  Scenario: New customer cannot create account with invalid email

    When I fill in the following:
    | Email            | invalid.address |
    | Password         | johndoe         |
    | Confirm Password | johndoe         |
    And I press "Create My Account"
    Then account creation should fail with "Email is invalid"

  Scenario: New customer cannot create account with duplicate email

    Given customer "Tom Foolery" exists
    When I fill in the following:
    | Email            | tom@foolery.com |
    | Password         | tom             |
    | Confirm Password | tom             |
    And I press "Create My Account"
    Then account creation should fail with "Email has already been registered"
    When I follow "Sign in as tom@foolery.com"
    Then I should be on the login page
    And the "email" field should be "tom@foolery.com"

  Scenario: New customer cannot create account without providing password

    When I fill in the following:
    | Email | john@doe.com |
    And I press "Create My Account"
    Then account creation should fail with "Password is too short"
    
  Scenario: New customer cannot create account with mismatched password confirmation

    When I fill in the following:
      | Email            | john@doe.com  |
      | Password         | johndoe       |
      | Confirm Password | johndo        |
    And I press "Create My Account"
    Then account creation should fail with "Password confirmation doesn't match"

                                            
