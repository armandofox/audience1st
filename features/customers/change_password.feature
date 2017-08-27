Feature: customer can change password

  As a customer
  So that my password can be easier to remember
  I want to be able to change my password

Background: I am logged in

  Given customer "Tom Foolery" has email "tom@foolery.com" and password "pass"
  And I am logged in as customer "Tom Foolery"
  And I visit the change password page

Scenario: supply new valid password

  When I fill in "New Password" with "syzygy"
  And I fill in "Confirm New Password" with "syzygy"
  And I press "Save Changes"
  Then I should be able to login with username "tom@foolery.com" and password "syzygy"

Scenario: confirmation mismatch

  When I fill in "New Password" with "syzygy"
  And I fill in "Confirm New Password" with "yzy"
  And I press "Save Changes"
  Then I should see "Password confirmation doesn't match Password"
  And I should be able to login with username "tom@foolery.com" and password "pass"

Scenario: supply blank password

  When I fill in "New Password" with ""
  And I press "Save Changes"
  Then I should see "Password is too short"
  And I should be able to login with username "tom@foolery.com" and password "pass"
  
