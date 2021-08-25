Feature: import Goldstar sales

  As a boxoffice manager
  To easily merge Goldstar sales into our own sales
  I want to import Goldstar sales lists that don't include patron email addresses

Background: logged in as boxoffice

  Given I am logged in as boxoffice
  And I am on the ticket sales import page
  And a show "Hand to God" with the following tickets available:
    | qty | type                          | price  | showdate                 |
    |   5 | Goldstar - General (external) | $15.00 | January 12, 2010, 8:00pm |
    |   5 | Goldstar - Comp (external)    | $0.00  | January 12, 2010, 8:00pm |

Scenario: successful import creates new customers; then attempt re-import of same file

  When I upload the "Goldstar" will-call file "2010-01-12-HandToGod.json"
  Then table "#proposed_import" should include:
    | Name on import    | Import to customer       | Tickets                                                                                                                      |
    | Chewning, Lynn    | Will create new customer | 2 @ Hand to God - Tuesday, Jan 12, 8:00 PM - Goldstar - General                                                              |
    | Granding, Annabel | Will create new customer | 1 @ Hand to God - Tuesday, Jan 12, 8:00 PM - Goldstar - General                                                              |
    | Melendrez, Rosa   | Will create new customer | 1 @ Hand to God - Tuesday, Jan 12, 8:00 PM - Goldstar - Comp1 @ Hand to God - Tuesday, Jan 12, 8:00 PM - Goldstar - General  |
  When I press "Import Orders"
  Then the following "Goldstar - General" tickets should have been imported for "Hand to God":
    | patron           | qty | showdate                 |
    | Lynn Chewning    |   2 | January 12, 2010, 8:00pm |
    | Annabel Granding |   1 | January 12, 2010, 8:00pm |
    | Rosa Melendrez   |   1 | January 12, 2010, 8:00pm |
  And the following "Goldstar - Comp" tickets should have been imported for "Hand to God":
    | patron         | qty | showdate                 |
    | Rosa Melendrez |   1 | January 12, 2010, 8:00pm |
  And I should see "5 tickets were imported for 3 total customers. None of the customers were already in your list. 3 new customers were created."
  But I should not see "This list contains an order for"
  When I visit the ticket sales import page for the most recent "Goldstar" import
  Then the import for "Chewning, Lynn" should show "View imported order" 
  And  I should not see "Import Orders"
  When I upload the "Goldstar" will-call file "2010-01-12-HandToGod.json"
  Then I should see "This list was already imported"
  And  I should be on the ticket sales import page
  When I visit the edit contact info page for customer "Rosa Melendrez"
  Then I should see "Created by Goldstar import on Jan 1, 2010" within "#adminPrefs"

Scenario: unique match on name defaults to using existing, but inexact multiple match defaults to create new

  Given the following customers exist: Lynn Chewning, R Melendrez, Rosa Melendrez, A Granding, Ann Granding
  When I upload the "Goldstar" will-call file "2010-01-12-HandToGod.json"
  Then the default import action for "Chewning, Lynn" should be "Lynn Chewning (lynn@chewning.com) (123 Fake St)"
  And the default import action for "Melendrez, Rosa" should be "Rosa Melendrez (rosa@melendrez.com) (123 Fake St)"
  But the default import action for "Granding, Annabel" should be "Create new customer"

Scenario: customer non-unique match, boxoffice agent decides whether to import as new or select existing; imported order shows original import name, not matched name

  Given customer "R Melendrez" exists with no email
  And customer "Annabelle Granding" exists with email "anng@example.com"
  When I upload the "Goldstar" will-call file "2010-01-12-HandToGod.json"
  And I select the following options for each import:
    | import_name       | action                                              |
    | Granding, Annabel | Annabelle Granding (anng@example.com) (123 Fake St) |
    | Melendrez, Rosa   | Create new customer                                 |
  And I press "Import Orders"
  And I should see "5 tickets were imported for 3 total customers. One customer was already in your list. 2 new customers were created."
  And customer "Annabelle Granding" should have 1 "Goldstar - General" tickets for "Hand to God" on Jan 12, 2010, 8:00pm
  And customer "Annabel Granding" should not exist
  And customer "Rosa Melendrez" should have 1 "Goldstar - Comp" tickets for "Hand to God" on Jan 12, 2010, 8:00pm
  But customer "R Melendrez" should have 0 "Goldstar - Comp" tickets for "Hand to God" on Jan 12, 2010, 8:00pm
  When I visit the ticket sales import page for the most recent "Goldstar" import
  Then the import for "Granding, Annabel" should show "View imported order"
  But I should not see "Granding, Annabelle"
  And I should not see "anng@example.com"

Scenario: possibly wrong show

  When I upload the "Goldstar" will-call file "wrong_show.json"
  Then I should see "This list contains an order for 'God Hand' on Tuesday, Jan 12, 8:00 PM, but the show name associated with that date is 'Hand to God'."
  But I should not see "This list contains an order for 'Hand to God'"

Scenario: mistakenly upload CSV rather than JSON

  When I upload the "Goldstar" will-call file "2010-01-12-HandToGod.csv"
  Then I should see "This appears to be a CSV file, but you must upload a JSON file."

Scenario: non-CSV, invalid JSON data

  When I upload the "Goldstar" will-call file "invalid.json"
  Then I should see "Invalid JSON"
  But I should not see "This appears to be a CSV file"
  
Scenario: nonexistent offer code

  When I upload the "Goldstar" will-call file "nonexistent_offer_id.json"
  Then I should see "This will-call list is invalid because at least one purchase (for Rosa Melendrez) refers to the nonexistent offer ID 999999."

Scenario: one of the claims is empty because of Goldstar bug or idiosyncrasy

  When I upload the "Goldstar" will-call file "empty_claim.json"
  Then I should see "Warning: purchase ID 11911841 for Annabel Granding has an empty 'claims' list."
  But I should not see "Warning: purchase ID 11926368 for Rosa Melendrez has an empty 'claims' list."
