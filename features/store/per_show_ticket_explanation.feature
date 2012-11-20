Feature: add ticket explanations specific to a show

  As a box office manager
  So that customers understand special restrictions associated with ticket purchases for a particular show
  I want to provide show-specific ticket explanations for some shows

Background:

  Given I am logged in as boxoffice manager
  And   a show "Chicago" with tickets on sale for today

Scenario: add ticket explanation to a show

  When I visit the show details page for "Chicago"
  And I fill in "Description (optional)" with "This show is racy"
  And I press "Save Changes"
  Then a show with name: Chicago should exist
  And the show should have description: "This show is racy"

Scenario: see show-specific description on ticket page

  Given a show with name: Chicago should exist
  And the show has description: "This show is racy"
  When I visit the store page for "Chicago"
  Then I should see "This show is racy"

Scenario: show without ticket explanation doesn't display anything

  Given a show "Cabaret" with tickets on sale for today
  And a show with name: Chicago should exist
  And the show has description: "This show is racy"
  When I visit the store page for "Cabaret" 
  Then I should not see "This show is racy"
  
  
