Feature: secret question for password recovery

  As a hapless customer
  So that I can login when forgetting my password
  I want to establish a secret question for login

Scenario: customer can establish a secret question

  Given I am logged in as customer "Tom Foolery"
  When I visit the change secret question page
  Then "(No question selected)" should be selected in the "Question" menu
  When I select "In what city were you born?" from "Question"
  And I fill in "Answer" with "New York"
  And I press "Save Changes"
  Then customer "Tom Foolery" should have secret question "In what city were you born?" with answer "New York"
  And I should see "Secret question change confirmed."

Scenario: customer without secret question is prompted to set one up on login

  Given I am not logged in
  When I am logged in as customer "Tom Foolery"
  Then I should see "You can now setup a secret question"
  When I follow "Change Password"
  Then I should be on the change password page
  And I should see "You don't have a secret question set up yet."

Scenario: customer with secret question does not see a reminder

  Given customer "Tom Foolery" has secret question "In what city were you born?" with answer "New York"
  And I am not logged in
  When I am logged in as customer "Tom Foolery"
  Then I should not see "You can now setup a secret question"
