Feature: Class enrollment requires attendee name

  As a box office manager
  So that I know who is actually enrolled in a class
  I want the customer to be required to provide names of enrolled actors

Background:

  Given a class "Acting 101" available for enrollment now
  And I am logged in as boxoffice manager
  When I visit the classes and camps page
  And I select "Acting 101" from "Class"
  And I fill in "General - $20.00" with "1"
  And I proceed to checkout
  Then I should be on the checkout page
  And I should see "Who is attending the class?"

Scenario: try to enroll without giving a name, even enforced for admins

  When I press "Accept Cash Payment"
  Then I should be on the checkout page
  And I should see "You must specify the enrollee's name for classes"

Scenario: try to enroll after providing a name
 
  When I fill in "pickup" with "John Doe" 
  And I press "Accept Cash Payment"
  Then I should be on the order confirmation page
