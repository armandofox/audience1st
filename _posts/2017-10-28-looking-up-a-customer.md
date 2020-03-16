---
layout: page
title: "Looking Up or Adding a Customer"
category: WorkingWithPatronRecords
date: 2017-10-28 16:14:16
order: 10
---
If you're logged in as any kind of admin (i.e. Staff or higher privilege), under the main navigation "tabs" is a yellow ribbon whose top line says something like "Customer: Armando Fox" and which contains several search boxes.  This is the customer navigation bar ("customer navbar"), which only admins can see.

There are two ways to search for a customer.  The "Quick search first or last name" will auto-complete possible customer matches as you type, but it will only match substrings in the customer's first or last name.  "Search any field" will find all matching customers by searching their name, address, comments, zip code, phone number, etc.

You can also browse the entire list of customers by clicking "All" in the customer navbar, and click on a customer to select them.

When you navigate to a customer, by default you will end up in their
"My Tickets" view, which shows their ticket purchases, reservations,
and subscription purchases.  Once there, you can also click the
Billing/Contact, Change Password, and other tabs to navigate to other
screens on behalf of that customer.

# When you have located the desired customer

No matter how you look up a customer, once you select them they become the "Current Customer", and their name now appears next to "Customer" in the customer navbar.

You are now acting on behalf of the current customer, and these
buttons appear in the secondary navbar:

* [Add Comps]({% post_url 2020-03-15-adding-comps %}) - add complimentary tickets to the customer's account, either open (unreserved) or reserved for a particular performance
* Orders - list this customer's order history
* Transfer - transfer items from this customer to another customer
* Donations - list this customer's donation history (actually an alias for the main Donations screen, but with "restrict to customer" selected)
* Transactions - database transaction log, semi-structured and variably useful
* New Donation - record a new donation for this customer

In addition, clicking the main navbar's "Buy Tickets" will [enter the
regular tickets sales flow]({% post_url 2020-03-15-telephone-sales %})
with this customer selected as the purchaser and recipient.  This
purchase flow is the same one the customer would see if they
self-purchase, except that their only payment option is credit card
whereas you can record a cash or check sale as well. 

Click "Billing/Contact" to see or modify the customer's contact information (mailing address, email, etc.)  You can make changes and click Save to update the customer's contact info.  The settings  "opt out of US mail" and "opt out of email" affect customer report generation and MailChimp integration if enabled.

A framed set of fields labeled "Administrator Preferences" displays customer information that only admins can see and change, including  Privilege level, Comments visible to staff only, and Labels, which lets you attach one or more labels of your own choosing ("Potential donor", "Advisory board member", "Community leader") that can be used later in reporting.

The "Do not email customer a confirmation of these changes" box is checked by default.  If you un-check it, then when you click "Save" to save changes to this customer, a summary email will be sent to them (if they have a valid email address) indicating the changes.  (Changes to admin-only-visible fields, such as Staff Comments or customer privilege level, will not be indicated in this confirmation email.)

# Manually Adding a New Customer

If the customer you're trying to serve is not in the A1 database, you
can manually add them.  (See also: [Merging Duplicate Customer
Profiles]({% post_url 2017-11-03-merging-duplicate-customer-profiles %}.)

Click "New..." in the customer navbar to manually enter information for a new customer.  Note that the first time they login they will have to use the "Forgot password" feature to set a password for themselves, and this is only possible if you include a correct email address when entering the new customer info.


