Feature: customer who forgot password can receive a new one by email

  As a customer who forgot my password
  So that I can login
  I want to generate a new password by email

Scenario: send magic link to user
Given it is currently 'January 1, 2019 12:00'
  Given customer "John Doe" exists and was created by admin
  When I seed with 1
  When I visit the forgot password page
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=pho4w5q0iwnrrc"
  Given "john@doe.com" opens the email
  And it is currently 'January 1, 2019 12:09'
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=pho4w5q0iwnrrc" 
  Then I should be on the change password page

Scenario: no forgot password email is sent if email does not exist
  When I visit the forgot password page
  And I fill in "email" with "bchillz@gmail.com"
  And I press "Reset My Password By Email"
  Then I should be on the forgot password page 
  And I should see "is not in our database. You might try under a different email, or create a new account."

Scenario: invalid magic link does not work
  Given customer "John Doe" exists and was created by admin
  When I seed with 2
  When I visit the forgot password page
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=m1c48izerc1nbal"
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=invalid"
  And I should be on the login page
  And customer "John Doe" should not be logged in

Scenario: magic link expires after 10 minutes
  Given it is currently 'January 1, 2019 12:00'
  And customer "John Doe" exists and was created by admin
  When I seed with 3
  When I visit the forgot password page
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=i077alg5n1htptl"
  Given "john@doe.com" opens the email
  And it is currently 'January 1, 2019 12:11'
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=i077alg5n1htptl" 
  And I should be on the login page
  And customer "John Doe" should not be logged in
  
  
  
  
  

  
