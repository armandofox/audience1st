Feature: automatic import of will-call email from Goldstar

  As a box office manager
  So that I can save time and avoid transcription errors
  I want to have my Goldstar will-calls imported automatically from their email

Scenario: successful import

  Given a "Goldstar 1/2 price" vouchertype costing $11.00 for the 2011 season
  And a valid Goldstar will-call email "valid.eml" for "Of Mice and Men" on Sunday, February 6, 2011
  When that email is received and processed
  Then customer Heebok Park should have 2 "Goldstar 1/2 price" tickets for "Of Mice and Men" on Sunday, February 6, 2011
  And  customer Marvel Pierce should have 2 "Goldstar 1/2 price" tickets for "Of Mice and Men" on Sunday, February 6, 2011
