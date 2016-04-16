Feature: RSS feed for availability

Scenario: availability has unescaped links

  Given a class "Acting" available for enrollment now
  When I visit the "availability" RSS feed
  Then the feed should contain the following elements:
  | element | regexp | should_match |
  | link    | &amp   | false        |

