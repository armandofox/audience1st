Feature: add comps and reserve for a show

  As a box office worker
  So I can comp my best customers
  I want to add comp tickets for a particular performance

Background: logged in as admin and shows are available

  Given I am logged in as boxoffice manager
  And I am acting on behalf of customer "Tom Foolery"
  And 10 "Comp" comps are available for "Macbeth" on "April 20, 2013, 8pm"
  And I am on the add comps page

  
  
