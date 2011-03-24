Feature: secret question for password recovery

  As a hapless customer
  So that I can login when forgetting my password
  I want to establish and use a secret question for login

Scenario: customer can establish a secret question

  Given I am logged in as customer "Tom Foolery"
  When I visit the change password page
  Then "(No question selected)" should be selected in the "Question" menu
  When I select "In what city were you born?" from "Question"
  And I fill in "Answer" with "New York"
  And I fill in "New Password" with "smoozywat"
  And I fill in "Confirm New Password" with "smoozywat"
  And I press "Save Changes"
  Then customer "Tom Foolery" should have secret question "In what city were you born?" with answer "New York"
  And I should see "Changes confirmed."

Scenario: customer can login by answering secret question correctly

Scenario: customer cannot login if secret question answered incorrectly

Scenario: customer cannot login if secret question hasn't been selected
