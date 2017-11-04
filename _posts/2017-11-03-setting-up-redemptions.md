---
layout: page
title: "Setting Up Redemptions"
category: season
date: 2017-11-03 19:11:07
order: 40
---


A voucher type just specifies how much a ticket costs and who is allowed to buy it; it doesn't specify what performances it's valid for, or what the sales period is for that type of ticket for that performance. That information is carried in a **redemption**, which associates a particular voucher type with one or more performances for which that type of voucher can be used, and possibly specifies start/end sales dates, capacity controls, and promo-code-controlled discounts for that voucher type.

Click on the Season tab, click on a show name, and click Add Ticket Type to All Performances.  You can then choose a voucher type that can be redeemed for performances of that show and specify when sales of that voucher type begin and end.

You can also click on "New..." under a particular performance to add a voucher type to just selected performances.

You can also specify capacity controls, so that certain voucher types (e.g. discount tickets) are quantity-limited per performance, and "promo codes" that patrons can type in to reveal vouchers at special prices.

You can also associate specific voucher types with only a particular performance rather than all performances.  To do this, click on the Season tab, then the show name, and next to the desired performance click "Show Ticket Details".  This will reveal all voucher types that can be redeemed for that performance; you can add a new voucher type (click "Add New...") or make changes to the existing ones.  

You cannot delete a voucher type from a performance if some vouchers of that type have already been sold; however, you can prevent further sales of that voucher type by adjusting its "max sales" limit to the number already sold for that performance.

## Redemptions: An Example (Single Tickets)

Suppose we have a run of the play Hamlet, every Fri, Sat and Sun night from Jan 1-17, 2015 (nine performances), and we have a house capacity of 100.  Our general admission price is $40 adults, $25 youth, but we also want to do promotions to sell more seats at matinees.  We might set up tickets and validity records as follows:

| Voucher type and price | Validity |
|------------------------|----------|
| Adult General, $40     | All performances; unlimited sales; advance sales stop 3 hours before performance |
| Youth General, $25     | All performances; unlimited sales; advance sales stop 3 hours before performance |
| Matinee Special, $20   | Sunday shows only; sales limited to 30 per show; advance sales stop 2 days before performance |

This way, even if the matinee special is really popular, at most 30 such tickets can be sold for each matinee.

When a customer is on the "Buy Tickets" page and selects a particular performance, only the voucher types whose validity records allow that performance will be shown.  So, for example, if there were seats available for the Sunday Jan. 3 matinee but all 30 Matinee Special seats had been sold, the patron could still buy Adult General or Youth General seats for that performance, but not Matinee Special seats.  The same would happen if there were still Matinee Special seats left but the show was less than 2 days away, since the Matinee Special validity record says that sales of those tickets must stop 2 days before the performance.

## Redemptions: An Example (Subscriptions)

 The simplest subscription is "one ticket to each of our 3 shows this season" (let's say Hamlet, Othello, and King Lear).  To sell this subscription, you'd create a voucher type corresponding to a subscriber reservation for each of the shows.  The Hamlet subscriber voucher could be valid for any performance of Hamlet, but not for any other production; and so on.

You can also create bundles that are more restrictive.  For example, a "matinees only" subscription would require creating three more voucher types whose validity records would indicate they're only valid for matinees.  The validity records of the six vouchers in this scenario might then be:

| Voucher type | Validity |
|------------------------|----------|
| "Hamlet" - subscriber | All performances of Hamlet; unlimited sales |
| "Hamlet" - subscriber - Matinees only | Matinee performances of Hamlet; unlimited sales |
| "Othello" - subscriber | All performances of Hamlet; unlimited sales |
| "Othello" - subscriber - Matinees only | Matinee performances of Hamlet; unlimited sales |
| "King Lear" - subscriber | All performances of Hamlet; unlimited sales |
| "King Lear" - subscriber - Matinees only | Matinee performances of Hamlet; unlimited sales |
| Regular Subscription - $100 | Contains one each of "Hamlet - subscriber", "Othello - subscriber", "King Lear - subscriber" |
| Matinee-Only Subscription - $75 | Contains one each of "Hamlet - subscriber (Matinees only)", "Othello - subscriber (Matinees only)", "King Lear - subscriber (Matinees only)" |

If your subscription is more flexible--for example, "3 tickets to our
regular productions, to use as you see fit"--you might create just a
single "Subscriber voucher" type and declare it to be valid for any
performance of any show.  You can also create "family pack" bundles that
contain (for example) 2 "Adult subscriber" and 2 "Youth subscriber"
tickets, and so on.
