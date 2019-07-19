Feature: set up new show
  
  As the Box Office Manager
  So that I can sell tickets for a show
  I want to setup the new show

Background:

  Given I am logged in as a box office manager
  And there is no show named "Chicago"

Scenario: Setup new show

  When I go to the New Show page
  And I fill in the "show" fields as follows:
  | field                                                          | value                        |
  | Show Name                                                      | Fiddler on the Roof          |
  | House capacity                                                 | 50                           |
  | List starting                                                  | select date "2010-03-11"     |
  | Event type                                                     | select "Regular Show"        |
  | Landing page URL (optional)                                    | http://mytheatre.com/fiddler |
  | Description (optional)                                         | A classic                    |
  | Special notes to patron (in confirmation email); blank if none | Enjoy                        |
  | If show is sold out, dropdown says:                            | Sold Out!                    |
  | If show is sold out, information for patron                    | Tough                        |
  And I press "Create Show"
  Then I should be on the show details page for "Fiddler on the Roof"
  And the show "Fiddler on the Roof" should have the following attributes:
    | attribute                 | value                        |
    | name                      | Fiddler on the Roof          |
    | event_type                | Regular Show                 |
    | landing_page_url          | http://mytheatre.com/fiddler |
    | house_capacity            | 50                           |
    | sold_out_dropdown_message | Sold Out!                    |
    | sold_out_customer_info    | Tough                        |
    | description               | A classic                    |
  When I fill in the "show" fields as follows:
    | field                       | value                    |
    | House capacity              | 100                      |
    | List starting               | select date "2010-04-11" |
    | Landing page URL (optional) | http://mytheatre.com/fid |
  And I press "Update Show"
  Then the show "Fiddler on the Roof" should have the following attributes:
    | attribute                 | value                    |
    | landing_page_url          | http://mytheatre.com/fid |
    | house_capacity            | 100                      |
    | listing_date              | 2010-04-11               |
    | sold_out_dropdown_message | Sold Out!                |
    | sold_out_customer_info    | Tough                    |
    | description               | A classic                |

