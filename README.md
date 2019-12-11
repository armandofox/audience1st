[![Maintainability](https://api.codeclimate.com/v1/badges/f023aeddae42d2da37ba/maintainability)](https://codeclimate.com/github/armandofox/audience1st/maintainability)
[![Build Status](https://travis-ci.org/armandofox/audience1st.svg?branch=master)](https://travis-ci.org/armandofox/audience1st)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f023aeddae42d2da37ba/test_coverage)](https://codeclimate.com/github/armandofox/audience1st/test_coverage)

Audience1st was written by [Armando Fox](https://github.com/armandofox) with contributions from:
[Xiao Fu](https://github.com/fxdawnn),
[Jasper Gan](https://github.com/jasgan)
[CiCi Huang](https://github.com/chengchenghuang),
[Xu Huang](https://github.com/Hexhu),
[Xiaoyu He (Alan)](https://github.com/AlanHe-Xiaoyu),
[Wayne Leung](https://github.com/WayneLeung12),
[Autumn Li](https://github.com/autumnli11)
[Yowsean Li](https://github.com/yowsean),
[Anthony Ling](https://github.com/Ant1ng2),
[Jason Lum](https://github.com/jayl109),
[Sanket Padmanabhan](https://github.com/sanketq),
[Andrew Sun](https://github.com/andrewsun98),
[Tanji Saraf-Chavez](https://github.com/tsarafchavez),
[Jack Wan](https://github.com/WanNJ),
[Alex Wang](https://github.com/raisindoc),
[Kevin Yen](https://github.com/crazyberry7)
[Casper Yang](https://github.com/cyang2020),
[Hang (Arthur) Yin](https://github.com/LoserNoOne)


# This information is for developers and deployers

Perhaps you intended to [learn about Audience1st features and/or have us install and host it for you](https://docs.audience1st.com)?

You only need the information in this repo and its wiki if you are deploying and maintaining Audience1st yourself.  If so, this page assumes you are IT-savvy and provides the information needed to help you get this Rails 4/Ruby 2.5 app deployed.

# Preparing to develop

In addition to the app, you will need a Stripe account, though you can 
use just the test-mode keys during development.

## Multi-tenant setup

**This is important.** By default Audience1st is designed to be setup
as [multi-tenant using the `apartment`
gem](https://github.com/influitive/apartment), where each theater is a
tenant.  Audience1st determines the tenant name for a given request
fomr the first subdomain in the URI, e.g. if your deployment domain is
`somewhere.com`, then `my-theater.somewhere.com` selects `my-theater`
as the tenant for that request.

For development or staging, the recommended approach is to setup a
single tenant.  In this example we will call it `my-tenant-name`; you can
call it whatever you want, but if you deploy to Heroku for staging,
the app name `my-tenant-name.herokuapp.com` must exist, so choose
the name carefully.

1.  Create a file `config/application.yml` containing the following:

```yaml
tenant_names: my-tenant-name
session_secret: "exactly 128 random ASCII characters"
attr_encrypted_key: "exactly 32 random characters"
STRIPE_KEY: "Publishable key from a Stripe account in test mode"
STRIPE_SECRET: "Secret key from a Stripe account in test mode"
```

(In a production setting, you'd have several tenant names separated by
commas.)
**Please don't version this file or include it in pull requests, nor
modify the existing `config/application.yml.asc`.  The `.gitignore` is
set to ignore `config/application.yml` when versioning.** 

2. Create a `config/database.yml` file (and don't version it; it is
also git-ignored) containing `development:` and
`test:` targets:

```yaml
development:
  adapter: sqlite3
  database: db/my-tenant-name.sqlite3
test:
  adapter: sqlite3
  database: db/test.sqlite3
```

(The `production` configuration, if any, depends on your deployment
environment.  Heroku ignores any `production` configuration because it
sets its own using PostgreSQL.)

3.  After running `bundle` as usual, you can run `bundle exec rake
db:schema:load` to load the database schema into each tenant.

4.  Run `rake db:seed` on the development database,
which creates a few special users, including the administrative user
`admin@audience1st.com` with password `admin`.

5.  To start the app, say `rails server webrick` as usual (assuming you
want to use the simpler Webrick server locally; the `Procfile` uses 
a 2-process Puma server for the production environment currently), but in your
browser, **do not** try to visit `localhost:3000`; instead visit
`http://my-tenant-name.lvh.me:3000` since the multi-tenant
selection relies on the first component of the URI being the tenant
name.  This uses the [free lvh.me
service](https://nickjanetakis.com/blog/ngrok-lvhme-nipio-a-trilogy-for-local-development-and-testing#lvh-me)
that always resolves to `localhost`.

5.  The app should now be able to run and you should be able to login
with the administrator password.  Later you can designate other users as administrators.

5.  If you want fake-but-realistic data, also run the task
`TENANT=my-tenant-name bundle
exec rake staging:initialize`.  This creates a bunch of fake users,
shows, etc., courtesy of the `faker` gem.

# Deploying to production or staging

These instructions are for Heroku and assume that you have created a
Heroku app container and provisioned it with the basic (free) level of
Heroku Postgres.  You can adapt these instructions for other
deployment environments.

1. Get the code pushed to the deployment environment (`git push heroku
master` usually).

2. Ensure that the `config/application.yml` on your development
computer contains the correct configuration data.

3. If using Heroku, `figaro heroku:set -e production` to make
`application.yml`'s environment variables available to Heroku.

4. In addition, ensure that the environment variable `tenant_names` in
your deployment environment is set to a comma-separated list of all
your tenants.  For staging-type deployments to Heroku, the correct
value is the Heroku appname, so if your app is
`luminous-coconut.herokuapp.com`, the `tenant_names` environment
variable should be set to `luminous-coconut`.  (It's best **not** to
put this in `config/application.yml`, because you may have different
tenant(s) in development than in production/staging.)

5.  If this is the first deployment, `heroku run rake db:migrate` 
to create all the tenant schemata,
then `heroku run rake db:seed` to create the basic admin
account for each tenant.  Only portable SQL features are used,
and the schema has been tried with MySQL, Postgres, and SQLite.

6. If the environment variable `EDGE_URL` is set on Heroku,
`config.action_controller.asset_host` will be set to that value to
serve static assets from a CDN, which you must configure (the
current deployment uses the Edge CDN add-on for Heroku, which uses
Amazon CloudFront as a CDN).  If not set, assets will be served the
usual way without CDN.  (If you're just deploying a staging server,
you should not set this variable.)

7. The task `Customer.notify_upcoming_birthdays` emails an administrator or boxoffice manager with information about customers whose birthdays are coming up soon.  The threshold for "soon" can be set in Admin > Options.

## Integration: Sending transactional email in production

In production, email confirmations are sent for various things.
Audience1st is configured to use Sendgrid.  If you do nothing,
transactional emails will be suppressed in your staging/production
environment.  If you want to use
Sendgrid for real email sending in your staging/production app, do the following:

1. Provision the Sendgrid add-on for Heroku and obtain a Sendgrid API key.

2. `config/application.yml` file should contain a valid Sendgrid API key
value for `SENDGRID_KEY`.  You may need to `figaro heroku:set -e
production` to get the key value into Heroku's production environment.

3. Login to Audience1st as
an administrator, go to Options, and enter the Sendgrid domain
(i.e. the domain from which transactional emails will appear to come,
usually something like `your-app.herokuapp.com` for a staging
environment).

4.  Be sure that same domain name appears among the "allowed domains"
in the Sendgrid settings, which can be accessed via the Resources >
Sendgrid control panel in Heroku.


## Integration: MailChimp

In production, Audience1st can export customer lists (reports) to
Mailchimp to serve as the basis of a targeted email campaign.  To
enable this, log in to Audience1st as an administrator, go to Options,
and enter a Mailchimp key.  If left blank, Mailchimp integration is
disabled.

# To disable or change multi-tenancy

This requires removing a few files.  **Do not make any PRs that delete those files** since we need
them in the main/production version.  

1. Remove `gem 'apartment'` from the `Gemfile` before running `bundle
install`

2. Remove the file `config/initializers/apartment.rb`

3. Make sure your `config/application.yml` does **not**
contain any mention of `tenant_names`

# To change the tenant selection scheme

If you decide to use multi-tenancy but change the
tenant-selection scheme in `config/initializers/apartment.rb` 
(see the `apartment` gem's documentation for
what this means), you'll also need to edit the before-suite logic in
`features/support/env.rb` and `spec/support/rails_helper.rb`.  Those
bits of code ensure that testing works properly with multi-tenancy
enabled, but they rely on the tenant name being the DNS subdomain.  If
you don't know what this means, you should probably ask for assistance
deploying this software. :-)
