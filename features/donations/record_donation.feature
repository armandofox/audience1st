Feature: record donation

  As the development manager
  So that I can track donations and properly date them
  I want to record donations and be able to set date and comments

Background:

  Given I am logged in as boxoffice manager
  And I am on the record donation page for customer "Tom Foolery"

Scenario: record valid cash or check donation

  When I record a check donation of $55.55 to "General Fund" on Jan 1, 2009 with comment "Check #2222"



Scenario: 
