@wip

Feature: Creating an account
  As an anonymous customer
  I want to be able to create an account
  So that I can be one of the cool kids

  #
  # Account Creation: Get entry form
  #
  Scenario: Anonymous customer can start creating an account
    Given an anonymous customer
    When  she goes to /customers/new
    Then  she should be at the 'customers/new' page
     And  she should see a <form> containing a textfield: 'Email', password: Password, password: 'Confirm Password', submit: 'Create My Account'

  #
  # Account Creation
  #
  Scenario: Anonymous customer can create an account
    Given an anonymous customer
     And  no customer with first_name: 'Oona' exists
    When  she registers an account as the preloaded 'Oona'
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Welcome, Oona'
     And  a customer with first_name: 'Oona' should exist
     And  the customer should have first_name: 'Oona', and email: 'unactivated@example.com'
     And  unactivated@example.com should be logged in


  #
  # Account Creation Failure: Account exists
  #


  Scenario: Anonymous customer can not create an account replacing an activated account
    Given  an activated customer named 'Reggie'
    And    an anonymous customer
    When  she registers an account with first_name: 'foobar', last_name: 'foobar', password: 'monkey', and email: 'registered@example.com'
    Then  she should be at the 'customers/new' page
     And  she should see an errorExplanation message 'Email address registered@example.com has already been registered'
     And  a customer with first_name: 'Reggie' should exist
     And  the customer should have email: 'registered@example.com'
     And  she should not be logged in

  #
  # Account Creation Failure: Incomplete input
  #
  Scenario: Anonymous customer can not create an account with incomplete or incorrect input
    Given an anonymous customer
     And  no customer with first_name: 'Oona' exists
    When  she registers an account with first_name: '',  last_name: 'Ooblick',  password: 'monkey', password_confirmation: 'monkey' and email: 'unactivated@example.com'
    Then  she should be at the 'customers/new' page
     And  she should     see an errorExplanation message 'First name is too short'
     And  no customer with first_name: 'Oona' should exist

  Scenario: Anonymous customer can not create an account with no password
    Given an anonymous customer
     And  no customer with first_name: 'Oona' exists
    When  she registers an account with first_name: 'Oona',  last_name: 'Ooblick',  password: '',       password_confirmation: 'monkey' and email: 'unactivated@example.com'
    Then  she should be at the 'customers/new' page
     And  she should     see an errorExplanation message 'Password is too short'
     And  no customer with first_name: 'Oona' should exist

  @ip
  Scenario: Anonymous customer can not create an account with mismatched password & password_confirmation
    Given an anonymous customer
     And  no customer with first_name: 'Oona' exists
    When  she registers an account with first_name: 'Oona',  last_name: 'Ooblick',  password: 'monkey', password_confirmation: 'monkeY' and email: 'unactivated@example.com'
    Then  she should be at the 'customers/new' page
     And  she should     see an errorExplanation message 'Password doesn't match confirmation'
     And  no customer with first_name: 'Oona' should exist

  Scenario: Anonymous customer can not create an account with bad email
    Given an anonymous customer
     And  no customer with first_name: 'Oona' exists
    When  she registers an account with first_name: 'Oona',  last_name: 'Ooblick',  password: 'monkey', password_confirmation: 'monkey' and email: ''
    Then  she should be at the 'customers/new' page
     And  she should     see an errorExplanation message 'Email is invalid'
     And  no customer with first_name: 'Oona' should exist
    When  she registers an account with first_name: 'Oona',  last_name: 'Ooblick',  password: 'monkey', password_confirmation: 'monkey' and email: 'unactivated@example.com'
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Welcome, Oona'
     And  a customer with first_name: 'Oona' should exist
     And  the customer should have first_name: 'Oona', and email: 'unactivated@example.com'
     And  unactivated@example.com should be logged in



