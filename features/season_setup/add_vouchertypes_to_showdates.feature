Feature: add vouchertype(s) to showdate(s)

  As a boxoffice manager
  So that I can make tickets available for shows
  I want to add vouchertypes to existing showdates

Background: logged in as boxoffice managing existing showdates

  Given I am logged in as boxoffice manager
  And a show "Chicago" with the following performances: Feb 15 8pm, Feb 19 8pm, Feb 20 3pm

Scenario: cannot add vouchertypes that are already valid for a given showdate

  
