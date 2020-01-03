Feature: change seatmap after seats have been sold for a show

  As a box office manager
  So I can keep up with changing theater configurations before the show goes up
  I want to be able to change a seatmap after tickets have been sold

Background: two seatmaps exist

  Given a seatmap "S1" with seats A1,  B1,B2
  And   a seatmap "S2" with seats A1,A2,  B2
  
  And customer "Harvey Schmidt" has seats A1,B1

Scenario: All existing patrons can be accommodated in new seatmap

Scenario: Some patrons must be reassigne to new seats

  
