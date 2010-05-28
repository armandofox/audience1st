Feature: link with Facebook

  As a patron who has a Facebook account
  I want to link my Audience1st account with Facebook
  So that I can avoid remembering 2 logins and see which of my friends
    are attending shows

Scenario: login from Facebook

  Given I am logged in with linked Facebook account "armando"
  And I go to the home page
  Then I should be on the home page
  And I should see "Welcome, Armando Fox" within "div[id=welcome][class=facebook]"

Scenario: link existing account 

