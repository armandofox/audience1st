@time
Feature: purchase tickets after performance starts

  As a customer attending a streaming performance
  So that I can still watch if I arrive a bit late
  I want to purchase tickets after the performance has started

  Background: a performance set up for at least some late sales

    Given a show "Chicago" with the following tickets available:
      | showdate         | type           | qty | price | sales_cutoff |
      | Jan 1, 2021, 8pm | Early purchase | 100 |    $25 |           10 |
      | Jan 1, 2021, 8pm | Late purchase  | 100 |    $23 |          -10 |
    And it is currently Jan 1, 2021, 8:05pm

  Scenario: performance and redemption both allow late sales

    Given sales for the "Jan 1, 2021, 8pm" performance end at "Jan 1, 2021, 8:30pm"
    When I go to the store page
    And I select "1" from "Early purchase - $25.00"
    And I select "1" from "Late purchase - $23.00"
    And I proceed to checkout
    Then the cart total price should be $48.00

  Scenario: performance allows late sale, but some redemptions do not

