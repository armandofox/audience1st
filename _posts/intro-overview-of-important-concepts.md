---
layout: page
title: "Overview of Important Concepts"
category: intro
date: 2017-11-03 17:50:44
order: 10
---


## Patrons and Orders

* The _patron_ is the unit to which most operations are indexed.

* Whenever a patron purchases something (even if the "purchase" is actually comped or consists of a donation rather than the purchase of tickets), an _order_ is created. The order collects all the items that were purchased together, the manner of payment, and so on.  An order is connected to both the person who paid and the person who received the products; these are often the same person, but might not be, for example in the case of gift purchases.  Orders can be fully or partially refunded, with the corresponding items then marked as canceled.

* A patron's view of their account is that it holds some number of _vouchers_.  Some of these may be _reserved_, for example if they bought tickets to a particular performance.  Some may be _open_, for example if they bought a subscription and want to reserve performance dates for specific shows.  Of those that are reserved, you may choose to allow patrons to self-cancel or self-change their reservations, or not.

## Voucher Types and Redemptions

During season setup, you specify one or more _voucher types_.  Typically, a voucher type is either a specific kind of ticket at a specific price point (e.g. "Adult General Admission" at $35.00; "Press Comp" at $0.00), or one of several tickets included in a bundle (see below).

A given voucher type is _not_ automatically valid for a specific performance.  A _voucher redemption record_ is required to make that connection.  In effect, a redemption record says: "This type of voucher [e.g. Adult General Admission] is valid for specific performance(s) of this production, possibly subject to sales cutoff dates and capacity restrictions."  

When you create any kind of voucher type, whether a single ticket type or a bundle, you can indicate whether purchasing that voucher qualifies the buyer as a Subscriber.
This is important because Audience1st
allows many operations to distinguish between Subscribers and
non-Subscribers.  For example, when a new Voucher Type is created, you
can specify whether it can be purchased by anyone or only by
Subscribers.  This makes it easy to offer premium tickets available only
for Subscribers, or a  general-admission ticket offered at a discount but only to
Subscribers.

## Privilege model

Each user of the system has one of six privilege levels.  A user of a higher level can do everything that a user of lower levels can do.  The levels in order of increasing privilege are:

0. Patron: The default level: can log into her own account, manage her own reservations, and edit her own contact information.

0. Staff: Can also generate reports, including mailing lists, box office statistics, etc. Can record donations, search and update patron contact information, and so on. This is the appropriate category for any staff member who needs reporting capabilities but does not deal directly with reservation processing.

0. Walkup Sales: can also do day-of-show box office procedures, such as generating the will-call list, processing walkup sales transactions, and generating the box office settlement report.

0. Box Office: Can also make and cancel advance reservations, search the patron database, update patron information, add and remove comp vouchers from patron accounts, refund orders.

0. Box Office Manager: Can also do season setup: add/edit shows, add/edit performance dates, add/edit voucher types and bundle types, determine which voucher types can be redeemed for which performances.

0. Admin: Can grant/revoke any of the above privileges to other users.

In this guide, "admin" refers loosely to any non-patron privilege level.

## Act on behalf of

All privilege levels Staff or higher can act on behalf of a patron. That is, they can search for a patron by name, view that account as if they were the patron, and generally do all the things the patron could do, acting on behalf of the patron.  

The user interface seen by staff and patrons is the same, but Staff see some additional controls and tabs that patrons do not see.  At the bottom of every page is a button "Regular Patron View" that lets the logged-in admin see that page as a regular patron would see it (if the page is accessible to patrons at all).

## Admins can override everything

Various features of Audience1st are designed to limit what patrons can do: how far in advance of a show they can reserve tickets, whether they can cancel their own reservations, and enforcement of capacity controls on both overall house size and ticket type inventories.

Admins of any level are immune to these restrictions.  They can oversell the house, redeem tickets not normally acceptable for a given performance, and even sell a ticket to a sold-out show that occurred in the past, whereas a regular patron can buy tickets/make reservations as specified by the deadlines and capacity controls that are specified when each production's ticketing is set up.

