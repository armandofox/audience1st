Feature: search donations

  As a development manager
  So that I can find our best donors to help grow the theater
  I want to search our donation history

Background:

  Given I am logged in as staff
  And customer "Tom Foolery" exists

Scenario: list all donations

  Given a donation of $10.00 on April 22, 2011 from Tom Foolery
  When I go to the donations page
  And I press 'Search'

