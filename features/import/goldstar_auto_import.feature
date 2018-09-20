@wip
Feature: automatic import of will-call email from Goldstar

  As a box office manager
  So that I can save time and avoid transcription errors
  I want to have my Goldstar will-calls imported automatically from their email

Scenario: successful import

  Given a "Goldstar 1/2 price" vouchertype costing $11.00 for the 2011 season
  And a performance of "Of Mice and Men" on Sunday, February 6, 2011, 2:00pm
  And a valid Goldstar will-call email "valid.eml" for "Of Mice and Men" on Sunday, February 6, 2011, 2:00pm
  When that valid email is received and processed by GoldstarAutoImporter
  Then customer "Heebok Park" should exist
  And customer "Heebok Park" should have 2 "Goldstar 1/2 price" tickets for "Of Mice and Men" on Sunday, February 6, 2011, 2:00pm
  And customer "Marvel Pierce" should have 2 "Goldstar 1/2 price" tickets for "Of Mice and Men" on Sunday, February 6, 2011, 2:00pm
