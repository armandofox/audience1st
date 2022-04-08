---
category: AdvanceSalesAndReservations
title: Cancelling a Performance
order: "16"
layout: page
---

Sometimes it happens: you unexpectedly need to cancel or reschedule a performance
for which tickets have been issued.  Audience1st can help ease the
pain of notifying and reaccommodating your patrons.

There are two possible scenarios:

1. You want to reschedule an existing performance, but keep all or
most reservations the same.  That is, mostly the same patrons will
come to that performance, just on a different date.
In that case, read [this article]({
post_url 2022-04-08-rescheduling-a-performance }).

2. You want to cancel a performance, reaccommodating patrons to
various other
existing performances or possibly to a new performance yet to be
added.  This article tells you how to do it.

    


The basic steps
are:

1. Immediately halt any further sales/reservations for the cancelled
performance

2. (Optional) If desired, arrange for single-ticket buyers
(non-subscribers) to be able to reaccommodate themselves.
(Subscribers can generally do this already, unless you've taken
specific steps in Season Setup to prevent it.)

3. Notify patrons.


## Step 1. Stop sales for the affected performance

[This article]({% post_url 2022-04-08-stopping-sales %}) explains how
to immediately stop all sales and reservations for a performance. 

Do this step for each cancelled performance.

## Step 2. (Optional) Arrange for single-ticket buyers to reaccommodate themselves.

When you first set up your single-ticket revenue vouchers, you may
have left unchecked the option for "Purchaser can
self-change/self-cancel."  In such cases, cancelling, refunding, or
changing a single-ticket buyer's ticket requires box office
intervention.

You may prefer to handle it the same way for reaccommodating
single-ticket buyers when a performance is cancelled.  But you also
have the option of allowing them to reaccommodate themselves without
box office intervention, by following these steps:

1. Go to Vouchers and filter to show Regular Revenue Vouchers.  Select
a revenue voucher that has redemptions valid for the cancelled
performance and click on its name to edit it.

2. Check the box "Purchaser can self-change/self-cancel" and save
changes.

3. Make a note to yourself that after the dust settles from the
cancelled performance, you should restore the previous value of this
checkbox if needed.

Note that this will also give the buyer the option to _refund_ their
own purchases of these vouchers, which most theaters normally don't
want; but presumably cancelling a performance is a special case.

## Step 3: Notify patrons

Assuming you have MailChimp connected to Audience1st, the following
will let you compose an email to notify all patrons _with valid email addresses_. 
In practice, this should be everyone except patrons that were
hand-entered without an email address by box office staff.

The idea is to identify all affected patrons, export that list to
Mailchimp, and compose and send an email there.

1. Go to the Reports tab, and in the Customer Lists section, select
"Attendance at specific performances."  Select the show and date of the
cancelled performance.  (You'll repeat this process for each
cancelled performance date.)

2. Under Report Filtering Options, check "Require valid email
address".

3. If you want to do separate email notifications to subscribers and
non-subscribers with separate instructions rather than a single email
with two sets of instructions, under Report Filtering Options use the
dropdown menu to select subscribers or non-subscribers as appropriate,
and repeat the process again later.

4. Under What To Do With the Results, select Create New Sublist, and
pick a descriptive name such as "Performance XYZ cancellation notice."

5. Click "Run Report."

6. Log in to your venue's MailChimp account and you will see a new
Static List Segment with the name you chose.  You can now compose a
message and send it just to that segment.
