Feature: set up new showdate

  As the Box Office Manager
  So that I can sell tickets for a show
  I want to setup a new showdate for that show

Background:

  Given I am logged in as a box office manager
  And there is a show named "Chicago" opening April 1, 2010
  And I go to the Show Details page for "Chicago"
  When I follow "Add a Performance"
  Then I should be on the on the New Showdate page for "Chicago"

Scenario: add new showdate

  When I select "April 7, 2010 8:00pm" as the "Date and time" date
  And I select "April 7, 2010 6:00pm" as the "Advance sales stop" date
  And I fill in "Max advance sales" with "100"
  And I press "Save"
  Then I should be on the Show Details page for "Chicago"
  And I should see "Apr 7, 8:00 PM"
  And I should see "6:00PM day of show"

  
