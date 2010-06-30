Feature: link with Facebook

  As a patron who has a Facebook account
  I want to link my Audience1st account with Facebook
  So that I can avoid remembering 2 logins and see which of my friends
    are attending shows

@cur
Scenario: login from Facebook with linked account

  Given I am logged in with linked Facebook account "armando"
  When I go to the home page
  Then I should be on the home page
  And I should see "Welcome, Armando Fox" within "div[id=welcome][class=facebook]"
  And armandofox@gmail.com should be logged in

Scenario: login from Facebook with unlinked account

  Given I am logged in with unlinked Facebook account "armando" id "8888"
  When I go to the edit contact info page
  Then I should see "Link your existing account?"


@cur
Scenario: link existing account to Facebook

  Given I am logged in as customer 'armando'
  When I go to the home page
  Then I should see /Link your (.*) account to Facebook/
  When I link with Facebook user "A Fox" id "99999"
  Then a customer with fb_user_id: 99999 should exist
  And armandofox@gmail.com should be logged in
  When I go to the home page
  Then I should not see /Link your (.*) account to Facebook/
  And I should see "Welcome, Armando Fox" within "div[class=facebook]"
  


