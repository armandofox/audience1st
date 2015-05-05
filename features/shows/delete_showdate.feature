Feature: delete showdate

  As a boxoffice manager
  To correct a setup error
  I want to delete or cancel a showdate

Background: logged in as boxoffice

  Given I am logged in as boxoffice manager
  And there is a show named "Hamlet" with showdates:
   | date              | tickets_sold |
   | 12/20/2011 8:00pm |            0 |
   | 12/22/2011 8:00pm |            5 |

Scenario: delete showdate that has no tickets sold

  When I delete the showdate "12/20/2011 8:00pm"
  Then there should be no show on "12/20/2011 8:00pm"

Scenario: cannot delete showdate with tickets sold

  When I visit the show details page for "Hamlet"
  Then show me the page
  Then there should be no "Delete" button for the showdate "12/22/2011 8:00pm"

  
