---
layout: page
title: "Customizing Patron Checkout View and Door List"
category: Customizing
order: 100
---


## Overall appearance (background, colors, etc.)

TBD show Div structure here and give example

## Reservation check-in and door list

The reservation check-in table is in a `div#checkin` and the door list
is in a `div#doorlist`.  Within each, you can control the appearance
of the columns for patron last name (`.lastname`), patron first name
(`.firstname`), seat assignments if reserved seating (`.seats`), name
of ticket type (`.vouchertype`), and the "index letter" in the
leftmost column of the door list (`.maincolumn`).  Use a selector such
as `#doorlist .seats` to style only the door list, or just `.seats` to
style the same way in both the door list and the checkin screen.

![questionmark](../assets/css-doorlist.png)

## Order checkout

The patron's view of the order summary at the time of payment can be
customized to highlight the show name, date, and so on in different
ways, by styling the CSS classes shown below.

![questionmark](../assets/css-checkout.png)
