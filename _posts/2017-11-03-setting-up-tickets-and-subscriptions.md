---
layout: page
title: Setting Up Tickets and Subscriptions
category: SeasonSetup
date: 2017-11-03T19:10:37.000+00:00
order: "30"

---
# Setting Up Voucher Types for the Season

A voucher type represents a particular type of ticket or other product
sold during a specific season, and can be in one of five categories:

* **Regular revenue**: A normal single ticket for which you charge money
* **Comp**: A single-ticket complimentary admission
* **Voucher included in a bundle**: A voucher only available as part of a package, such as a subscription that includes one ticket to each of 4 shows; these vouchers have no dollar value because they can only be purchased as part of a bundle
* **Bundle**: A collection of  vouchers that can be sold as a single product (like a subscription or two-fer)
* **Nonticket item**: An item with a price that is not a ticket; use this type of voucher to sell products (wine, raffle tickets, etc.) and collect fees (ticket-exchange fees, etc.)

Each voucher type is valid only for the specific season associated with
it, beginning on the season start date you specify in Admin > Options
and ending one year later.  Each new season, you need to create a new
set of voucher types for that season, even if many of the prices are the
same.  So, for example, a "General Admission" voucher created for the
2016 season cannot be associated with any 2017 shows; a new General
Admission voucher for 2017 must be created instead.

To view the existing vouchers, click the Vouchers tab and select the desired season. You may also filter the list of vouchers displayed by category (comp, bundle, etc.).

## Creating a new voucher type from scratch

To create a new voucher type, click "New Voucher Type" at the bottom of
the list of voucher types.  The fields you fill in will vary depending
on the type of voucher.

When do you need to create a new voucher type, vs. just adding additional redemptions (see below) for an existing one?

1. If it has a different price point, it needs to be a separate voucher type.
2. If you want to be able to track its sales separately (even at the same price point), it needs to be a separate voucher type.  For example, Youth and Senior tickets may cost the same, but if you want to break down the revenue from each in reporting, they should be different voucher types.
3. If you want a ticket type that is only valid for specific productions or performances, it probably needs to be a separate voucher type.

## Creating Bundles and Subscriptions

A special type of voucher is a _bundle_, which actually just collects together a bunch of other vouchers into a package.
Even though the bundle is itself a voucher, it's a voucher that cannot be redeemed for anything; think of it as a "container" for the rest of the vouchers in the bundle.  So when a patron buys (for example) a 4-show subscription, they are actually getting 5 vouchers: one representing the subscription itself, and one each for the 4 shows in the subscription.

Bundle vouchers have the special property that if a bundle is cancelled or transferred to another customer, all of its
constituent vouchers travel with it.  If you cancel and refund a subscription, that automatically cancels the vouchers included in it; if you transfer a subscription to another patron (maybe it had been intended as a gift), all the included vouchers go with it.

To create a bundle, you must _first_ create all of the voucher types
that will be part of the bundle, and they must have the category
"Subscriber voucher" (even if the bundle isn't actually a subscription
but just a package deal that doesn't make the buyer a subscriber).
Subscriber vouchers don't allow you to specify a price, because they
will only be sold as part of a bundle.  Then you create a new Bundle
type voucher and associate any number of bundled vouchers with it, and
set the price for the entire bundle.