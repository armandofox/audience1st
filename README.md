Audience1st was written by [Armando Fox](https://github.com/armandofox) with contributions from
[Xiao Fu](https://github.com/fxdawnn),
[Wayne Leung](https://github.com/WayneLeung12),
[Jason Lum](https://github.com/jayl109),
[Sanket Padmanabhan](https://github.com/sanketq),
[Andrew Sun](https://github.com/andrewsun98),
[Jack Wan](https://github.com/WanNJ)

# This information is for developers and deployers

Perhaps you intended to [learn about Audience1st features and/or have us install and host it for you](https://armandofox.github.io/audience1st/)?

You only need the information on this page if you are deploying and maintaining Audience1st yourself.  If so, this page assumes you are IT-savvy and provides the information needed to help you get this Rails 2/Ruby 1.8.7 app deployed.

**Note:** The app is about to be rolled to Rails 4.2.9.  Any maintainability/vulnerability issues are being addressed as part of that upgrade.

This is a stock Rails app, with the following exceptions/additions:

0. The task `Customer.notify_upcoming_birthdays` emails an administrator or boxoffice manager with information about customers whose birthdays are coming up soon.  The threshold for "soon" can be set in Admin > Options.

0. The task `EmailGoldstar.receive(STDIN.read)` should be invoked to consume incoming emails from Goldstar.  See the installation section on Goldstar integration, below.

# Required external integrations

Audience1st uses [Figaro](https://github.com/laserlemon/figaro) to manage secrets, so you must arrange for the file `config/application.yml` to exist in the app root directory on the deploy server (or if using Heroku, use Figaro's built-in Heroku integration to make the config values available on that platform).

A minimal `config/application.yml` should look like this.  Remember that Figaro lets you override these values per-environment, so
(e.g.) you could have a `test:` section that overrides the Stripe and email-integration API keys with test account keys.

```yaml
session_secret: "30 or more random characters string"
stripe_key: "stripe public (publishable) key"
stripe_secret: "stripe private API key"
# include at most one of the following two lines - not both:
email_integration: "MailChimp"  # if you use MailChimp, include this line verbatim, else omit
email_integration: "ConstantContact" # if you use CC, include this line verbatime, else omit
# if you included one of the two Email Integration choices:
mailchimp_key: "optional: if you use Mailchimp, API key; otherwise omit this entry"
constant_contact_username: "Username for CC login, if using CC"
constant_contact_password: "password for CC login, if using CC"
constant_contact_key: "CC publishable part of API key"
constant_contact_secret: "CC secret part of API key"
```

# First-time deployment

Deploy the app as you would a normal Rails app, including running the migrations to load up `schema.rb`.  Only portable SQL features are used, so although MySQL was used to develop Audience1st, any major SQL database **that supports nested transactions** should work.  (SQLite does not support nested transactions, and as such, some tests that simulate network errors during credit card processing may appear to fail if you run all the specs locally against SQLite.)

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

The primary models of interest are `Item`, `Customer`, `Show`, `Showdate`, `Vouchertype`.

The main model and table is the `Item` model, which has subclasses `Voucher` (ie ticket), `Donation`, `RetailItem`, and `CanceledItem`.  All live in a single `items` table using single-table inheritance.

If an `Item` is of subclass `Voucher`, it has various other FKs as well, notably to the `Vouchertype` model and (if the voucher is reserved as opposed to 'open') the `Showdate` model.  A `Vouchertype` is the "template" for a particular ticket type--name by which it's listed, price, who may purchase it (subscribers, box office only, anyone, etc.), which season it's valid for, etc.  A `Showdate` models a single performance, with a house capacity, start/end time, start/end sales dates, and so on.  A `Showdate` and `Vouchertype` are tied together by the model `ValidVoucher`, a join table that captures the idea of a particular type of voucher being valid for a particular performance (showdate), with optional capacity controls and promo codes for that particular (showdate, vouchertype) pair.

Finally, every `Item` has a FK to the `Order` model. An order consists of a single payment transaction, so details about the payment (credit card confirmation code, etc.) are part of the `Order` rather than each `Item`.  

An `Item` has two foreign keys to the `Customer` model: `customer_id` is the person who holds the item, and `purchaser_id` is the person who paid for it. These are often the same person but need not be (gift orders, etc.)

A schema diagram is coming soon. Most of the other tables handle ancillary work: `Options` tracks global option (settings) values, `Purchasemethod` (which really should just be some constants) are ways to pay for a purchase, and there's a few other tables that are largely self-explanatory.



