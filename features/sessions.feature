Customers want to know that nobody can masquerade as them.  We want to extend trust
only to visitors who present the appropriate credentials.  Everyone wants this
identity verification to be as secure and convenient as possible.

Feature: Logging in
  As an anonymous customer with an account
  I want to log in to my account
  So that I can be myself

  #
  # Log in: get form
  #
  Scenario: Anonymous customer can get a login form.
    Given an anonymous customer
    When  I go to the login page
    Then  I should see a <form> containing a textfield: Login Name, password: Password, and submit: 'Login'
  
  #
  # Log in successfully, but don't remember me
  #
  Scenario: Anonymous customer can log in
    Given an anonymous customer
     And  an activated customer named 'reggie'
    When  she creates a singular sessions with login: 'reggie', password: 'monkey', remember me: ''
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Logged in successfully'
     And  reggie should be logged in
     And  she should not have an auth_token cookie
   
  Scenario: Logged-in customer who logs in should be the new one
    Given an activated customer named 'reggie'
     And  an activated customer logged in as 'oona'
    When  she creates a singular sessions with login: 'reggie', password: 'monkey', remember me: ''
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Logged in successfully'
     And  reggie should be logged in
     And  she should not have an auth_token cookie
  
  #
  # Log in successfully, remember me
  #
  Scenario: Anonymous customer can log in and be remembered
    Given an activated customer named 'reggie'
    When  she creates a singular sessions with login: 'reggie', password: 'monkey', remember me: '1'
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Logged in successfully'
     And  reggie should be logged in
     And  she should have an auth_token cookie
	      # assumes fixtures were run sometime
     And  her session store should remember customer 'reggie'
   
  #
  # Log in unsuccessfully
  #
  
  Scenario: Logged-in customer who fails logs in should be logged out
    Given an activated customer named 'oona'
    When  she creates a singular sessions with login: 'oona', password: '1234oona', remember me: '1'
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Logged in successfully'
     And  oona should be logged in
     And  she should have an auth_token cookie
    When  she creates a singular sessions with login: 'reggie', password: 'i_haxxor_joo'
    Then  she should be at the login page
    Then  she should see a warning message 'Couldn't log you in as 'reggie''
     And  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id
  
  Scenario: Log-in with bogus info should fail until it doesn't
    Given an activated customer named 'reggie'
    When  she creates a singular sessions with login: 'reggie', password: 'i_haxxor_joo'
    Then  she should be at the login page
    Then  she should see a warning message 'Couldn't log you in as 'reggie''
     And  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id
    When  she creates a singular sessions with login: 'reggie', password: ''
    Then  she should be at the login page
    Then  she should see a warning message 'Couldn't log you in as 'reggie''
     And  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id
    When  she creates a singular sessions with login: '', password: 'monkey'
    Then  she should be at the login page
    Then  she should see a warning message 'Couldn't log you in as '''
     And  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id
    When  she creates a singular sessions with login: 'leonard_shelby', password: 'monkey'
    Then  she should be at the login page
    Then  she should see a warning message 'Couldn't log you in as 'leonard_shelby''
     And  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id
    When  she creates a singular sessions with login: 'reggie', password: 'monkey', remember me: '1'
    Then  she should be redirected to the home page
    When  she follows that redirect!
    Then  she should see a notice message 'Logged in successfully'
     And  reggie should be logged in
     And  she should have an auth_token cookie
	      # assumes fixtures were run sometime
     And  her session store should remember customer 'reggie'


  #
  # Log out successfully (should always succeed)
  #

  Scenario: Anonymous (logged out) customer can log out.
    Given an anonymous customer
    When  she goes to /logout
    Then  she should be redirected to the login page
    When  she follows that redirect!
    Then  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id

  Scenario: Logged in customer can log out.
    Given an activated customer logged in as 'reggie'
    When  she goes to /logout
    Then  she should be redirected to the login page
    When  she follows that redirect!
    Then  she should see a notice message 'You have been logged out'
     And  she should not be logged in
     And  she should not have an auth_token cookie
     And  her session store should not have customer_id

