---
layout: page
title: "Walkup Sales"
category: foh
date: 2017-11-04 13:48:59
order: 20
---


If you sell tickets at the box office right before showtime, you can use the Walkup Sales capability.
The Walkup Sales functionality can be accessed by any user whose privilege level is ``Walkup Sales'' or higher.

The Walkup Sales user interface assumes that you do not have time to collect identifying information (i.e. names and addresses) for walkup patrons.  All purchases recorded through the Walkup Sales interface are allocated to the **WALKUP CUSTOMER**, a fictitious placeholder customer that cannot be deleted.  Furthermore, walkup transactions are marked to distinguish them from advance-sales transactions, so that settlement reports based on night-of-show sales can be easily generated.

## When NOT to use the Walkup Sales interface

Two common scenarios may arise on a show night in which the Walkup Sales interface is not appropriate:

1. For whatever reason, you specifically _do_ want to tie a walkup
purchase to a particular individual.  In this case, you must enter it
just as you would a regular reservation transaction, presumably while
the angry mob waits their turn in line.  If the customer is already in
Audience1st this only takes a couple of clicks, but if it's a new
customer, you'll have to enter their information to create their
customer record. 

2. A Subscriber without an advance reservation wants to use a Subscriber
voucher as a walk-up.  (Your policy on whether to allow this and how to
handle it may vary.)  In this case, you must visit the Subscriber's
account and place the reservation just as you would for an advance
reservation.  Walkup Sales user privilege specifically allows this
operation, for this exact reason.  

## How to record walkup sales

Click the **Box Office** tab to go the front-of-house display, then the
**Walkup Sales** tab.  A two-column screen will appear. At the top of
the leftmost column, you can select a performance date (it defaults to
today's date).  Beneath that are dropdown menus for _every ticket type
allowed for walkup sales for this performance._  (When a ticket type is
set up, the box office manager can indicate whether that ticket type is
allowed to be sold to walkup patrons or not.)  

To record a walkup purchase, simply select the correct performance date,
then select the number(s) of ticket(s) of each type, and optionally add
any additional donation.

Then in the rightmost column, you can enter payment:

* To accept a cash payment, take the customer's money and select _Cash
or Zero-Revenue_, then click _Record Cash Payment or Zero Revenue
Transaction_.  (The latter option allows you to use the walkup screen
to issue comps, though we don't advise it because then you have no way
to track who used the comp.)

* To accept a check, select _Check_ and optionally enter the check
number or other info, then click _Record Check Payment_.

* To accept a credit card if you **do not** have a swipe reader, select
_Credit Card_, then enter the credit card information (CVV code in the
red field, followed by first and last name, card number, and
expiration date), then click _Charge Credit Card_.

* To accept a credit card payment if you **do have** a 
a [card swipe reader](../setup/using-a-credit-card-swipe.html), **you must** still manually enter the CVV code in
the red field 
(since this code number is not present on the magnetic stripe).
Then swipe the credit card through the reader to record the
charge.

After every walkup sale, the available-seat count and walkup-sales count
are adjusted.

## Recovering from errors

Did you accidentally sell a ticket for the wrong performance, or did you
mean to "tie" a ticket sale to an existing customer but you purchased it
using the walkup sales flow?  Click _Whoops, I Made a Mistake_ and you
can transfer selected vouchers to another performance or another
customer.

## Walkup Sales Report

The walkup sales report shows the total walkup sales broken down by
payment method, so you can reconcile the box office cash drawer at close
of boxoffice.

