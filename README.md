[![Maintainability](https://api.codeclimate.com/v1/badges/f023aeddae42d2da37ba/maintainability)](https://codeclimate.com/github/armandofox/audience1st/maintainability)
[![Build Status](https://travis-ci.org/armandofox/audience1st.svg?branch=master)](https://travis-ci.org/armandofox/audience1st)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f023aeddae42d2da37ba/test_coverage)](https://codeclimate.com/github/armandofox/audience1st/test_coverage)

Audience1st was written by [Armando Fox](https://github.com/armandofox) with contributions from
[Xiao Fu](https://github.com/fxdawnn),
[Wayne Leung](https://github.com/WayneLeung12),
[Jason Lum](https://github.com/jayl109),
[Sanket Padmanabhan](https://github.com/sanketq),
[Andrew Sun](https://github.com/andrewsun98),
[Jack Wan](https://github.com/WanNJ)


# This information is for developers and deployers

Perhaps you intended to [learn about Audience1st features and/or have us install and host it for you](https://armandofox.github.io/audience1st/)?

You only need the information on this page if you are deploying and maintaining Audience1st yourself.  If so, this page assumes you are IT-savvy and provides the information needed to help you get this Rails 4/Ruby 2.3 app deployed.

# Deployment

This is a stock Rails 4 app, with the following exceptions/additions:

1. The task `Customer.notify_upcoming_birthdays` emails an administrator or boxoffice manager with information about customers whose birthdays are coming up soon.  The threshold for "soon" can be set in Admin > Options.

2. The task `EmailGoldstar.receive(STDIN.read)` should be invoked to consume incoming emails from Goldstar.  See the installation section on Goldstar integration, below.

3. If the envariable `EDGE_URL` is set,
`config.action_controller.asset_host` will be set to that value (the
current deployment uses the Edge CDN add-on for Heroku, which uses
Amazon CloudFront as a CDN).

## Multi-tenancy

**This is important.**  By default Audience1st can be setup as
multi-tenant using the `apartment` gem.  If you're just setting up ticketing
for a single venue, multi-tenancy probably creates more problems for you
than it solves.

To **disable** multi-tenancy:

1. Remove `gem 'apartment'` from the `Gemfile` before running `bundle
install`

2. Remove the file `config/initializers/apartment.rb`

3. Make sure your `config/application.yml` (see below) does **not**
contain any mention of `tenant_names`

## Required external integrations

You will need to create a file `config/application.yml` containing the following:

```yaml
session_secret: "30 or more random characters string"
tenant_names: venue1,venue2,venue3
```

The `tenant_names` should **only** be present if using multi-tenancy.
Each tenant name is assumed to correspond to a subdomain, so in the
exame above, the appropriate tenant would be chosen based on the URL
subdomain (`venue1.myticketing.com`, `venue2.myticketing.com`, etc.)
Without this line, the domain/subdomain are irrelevant and there is only
a single tenant.

**Note:** If you decide to use multi-tenancy but change the
tenant-selection scheme (see the `apartment` gem's documentation for
what this means), you'll also need to edit the before-suite logic in
`features/support/env.rb` and `spec/support/rails_helper.rb`.  Those
bits of code ensure that testing works properly with multi-tenancy
enabled, but they rely on the tenant name being the DNS subdomain.  If
you don't know what this means, you should probably ask for assistance
deploying this software. :-)

## First-time deployment

Deploy the app as you would a normal Rails app, including `rake
db:schema:load` (don't try running the migrations, as many of them use
syntax that is long deprecated).  Only portable SQL features are used,
and the schema has been tried with MySQL, Postgres, and SQLite.

Then run the task `rake db:seed` on the production database, which creates a few special users, including the administrative user `admin@audience1st.com` with password `admin`.

The app should now be up and running; login and change the administrator password.  Later you can designate other users as administrators.

# Integration with Goldstar™

See the documentation on how Goldstar integration is handled in the administrator UI.

The way Goldstar works is they send your organization an email containing both the will-call list as a human-readable attachment (spreadsheet or PDF) and a link to download an XML representation of the will-call list.

Thus there are two ways you can get Goldstar will-call info for each performance into Audience1st:

1. You manually download the appropriate XML file, then use the Import mechanism in the Audience1st GUI

2. You arrange to forward a copy of Goldstar's emails to Audience1st.  Audience1st will parse the email to find the download URL, download the XML list, and parse it itself.

To support scenario 2, you must be able to configure your email system so that email received in a particular mailbox is piped to a program.  Arrange for any Goldstar emails to be fed to the following command line:

`RAILS_ENV=production $APP_ROOT/script/runner 'EmailGoldstar.receive(STDIN.read)'`

Whenever an email is fed to this task, it will eventually generate a notification email to an address specified in Admin > Options notifying someone of what happened.  If the email was a valid Goldstar will-call list, the notification will usually say "XX customers added to will-call for date YY".  If it was not a valid Goldstar will-call list, the notification will say something like "It didn't look like a will-call list, so I ignored it."


# Schema

The primary models of interest are:

* `items`: things patrons receive or pay for--tickets, donations, retail
purchases.
* `orders`: a group of things purchased as part of a single payment
transaction.
* `show` and `showdate` (1-to-many relation): a production and a
performance respectively.
* `vouchertype`: specific ticket names/types with price points and
season validity.

As is customary in Rails, a column whose name looks like
*something*`_id`  is a foreign key to the `somethings` table (note that
per Rails conventions, the table names are all plural but the
foreign key names are singular).

The main model and table is the `Item` model, which has subclasses
`Voucher` (ie ticket), `Donation`, `RetailItem`, and `CanceledItem`.
All live in a single `items` table using single-table inheritance; the
`type` column indicates which subclass (voucher, donation, etc.) each row is an instance of.

Every item that costs money to purchase has an `amount` field showing
what was actually paid for that item.

## Items of subclass `Voucher` represent tickets

* The foreign key `vouchertype_id` (to the `vouchertypes` table) tells what type of
ticket this is.  A vouchertype typically represents a named price point
(ticket type) during a particular season.

* The foreign key `order_id` tells which order this ticket was part of.
An order consists of a single payment transaction, so details about the
payment (credit card confirmation code, etc.) are part of the `Order`
rather than of each `Item`.  The order also has three foreign keys to
the `customers` table: `customer_id` (the customer holding the item),
`purchaser_id` (the customer who paid for the item, which might be
different if e.g. it's a gift order), and `processed_by_id` (the person
who placed the order, which could be box office staff, etc. if not the
customer herself).  These keys are duplicated in the `items` table but
really shouldn't be.

* If the voucher is reserved for a particular performance, the `showdate_id`
foreign key tells which performance; otherwise it's `NULL`.  A
`showdate` has a (local timezone) date and time and some other
properties, and a foreign key to which `show` (production) it's related to.

## A Vouchertype is like a template

A `Vouchertype` is the
"template" for a particular ticket type--name by which it's listed,
price, who may purchase it (subscribers, box office only, anyone, etc.),
which season it's valid for, etc.  A `Showdate` models a single
performance, with a house capacity, start/end time, start/end sales
dates, and so on.  A `Showdate` and `Vouchertype` are tied together by
the model `ValidVoucher`, a join table that captures the idea of a
particular type of voucher being valid for a particular performance
(showdate), with optional capacity controls and promo codes for that
particular (showdate, vouchertype) pair.  Note that the `ValidVoucher`
model and join table is only used at sales time to determine who is
allowed to buy what and when; it is irrelevant to determining what
tickets _have been sold_.

## How subscriptions are handled

A subscription is a special case of a bundle--a group of vouchers sold
together.  A vouchertype whose `category` attribute is `bundle` is actually a container
for the individual vouchers in that bundle.  An individual subscriber
voucher, such as a ticket for a specific production that's part of a
season subscription, has the category `subscriber` and must have a price
of zero, because it's actually just part of a bundle (subscription) that
has a nonzero price.  

A bundle voucher doesn't have to be a subscription; the `subscription`
attribute on the vouchertype tells whether purchasing this vouchertype
makes the buyer a Subscriber.  (So in principle you can be a subscriber
without buying an actual subscription.)  This is relevant because the
concept of "being a subscriber" is deeply wired into Audience1st in
terms of setting up ticket sales.

## Items of subclass `Donation` are donations

The foreign key `account_code_id` tells which fund the donation went to;
the `order_id` ties it to the order (which also gives payment
information, date of payment, etc.)

## The Customers table

The table is pretty standard, modulo a few "special" customers such as
the Anonymous Customer (to whom all walkup sales are linked), the
Boxoffice Daemon (which automatically processes orders from third-party
vendors such as Goldstar), and a few others.  All users of the system,
even if they are not actually customers (eg administrators, box office
staff, etc), must appear in this table or they cannot login.

Email addresses in this table are used for login, and must be unique.
Case does not matter.

## Other tables

Most of the other tables handle ancillary work: `Options` tracks global
option (settings) values, `Purchasemethod` (which really should just be
some constants) are ways to pay for a purchase, and there's a few other
tables that are largely self-explanatory. 

# Notes on testing

## Time

Many features depend on the current time (to test things like reservaion
cutoffs, etc.)  **All Cucumber scenarios fix the current date and time
as Jan 1, 2010, 00:00:00 in the application timezone** in
`features/support/env.rb`.  To suppress this for certain scenarios, tag
them with `@time`.

## Stubbing credit card payments

Most scenarios that test payments do stubbing (in `env.rb`) at the level
of the `Store` methods that wrap calls to Stripe.  A few scenarios use
the `FakeStripe` gem.

