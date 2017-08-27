Feature: secret question for password recovery

  As a customer who forgot my password
  So that I can login
  I want to login using my secret question

Background:

  Given customer "Tom Foolery" has email "tom@foolery.com" and password "pass"
  Given I am not logged in
  When I visit the Login With Secret Question page
  And I fill in "Email" with "tom@foolery.com"
  And I select "In what city were you born?" from "Secret Question"

Scenario: customer can login by answering secret question correctly

  Given customer "Tom Foolery" has secret question "In what city were you born?" with answer "New York"
  When I fill in "Your Answer" with "New York"
  And I press "Verify"
  Then customer "Tom Foolery" should be logged in

Scenario: customer cannot login if secret question answered incorrectly

  Given customer "Tom Foolery" has secret question "In what city were you born?" with answer "New York"
  When I fill in "Your Answer" with "San Francisco"
  And I press "Verify"
  Then customer "Tom Foolery" should not be logged in
  And I should see "Sorry, that isn't the answer"
  And I should be on the Login With Secret Question page

Scenario: customer cannot login if secret question hasn't been selected

  When I fill in "Your Answer" with "San Francisco"
  And I press "Verify"
  Then customer "Tom Foolery" should not be logged in
  And I should see "Sorry, but 'tom@foolery.com' never set up a secret question."
  And I should be on the login page


