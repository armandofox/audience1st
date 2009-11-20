Feature: Check in a patron

  As a box office worker
  So that I can track how many people have arrived for the show
  I want to check in an arriving patron

  Background:
    Given I am logged in as boxoffice
    And a customer named Joe Smith
    And customer Joe Smith has a ticket for today
    And I am on the checkin page

