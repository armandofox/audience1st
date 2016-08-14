[![Code Climate](https://codeclimate.com/github/armandofox/audience1st/badges/gpa.svg)](https://codeclimate.com/github/armandofox/audience1st)

# You may be able to ignore this information

You only need the information on this page if you are deploying and maintaining Audience1st yourself.  If so, this page assumes you are IT-savvy and provides the information needed to help you get this Rails 2/Ruby 1.8.7 app deployed.

# Legacy Ruby/Rails

The app is on Rails 2.3.18 (2.3.5 with security patches) and Ruby 1.8.7.  I've been meaning to migrate it to Rails 3 and then Rails 4.  Help welcome.

But for now you'll have to get Rails 2.3.18 and Ruby 1.8.7 deployed on whatever host you want to deploy to.  I've been using Rackspace with Apache, mod_rails, and Phusion Passenger.

This is a stock Rails app, with the following exceptions/additions:

0. The task `Customer.notify_upcoming_birthdays` emails an administrator or boxoffice manager with information about customers whose birthdays are coming up soon.  The threshold for "soon" can be set in Admin > Options.

0. The task `EmailGoldstar.receive(STDIN.read)` should be invoked to consume incoming emails from Goldstar.  See the installation section on Goldstar integration, below.

# Required external integrations

You will need to create a file `config/application.yml` containing the following:

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


