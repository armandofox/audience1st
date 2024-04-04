[![Maintainability](https://api.codeclimate.com/v1/badges/f023aeddae42d2da37ba/maintainability)](https://codeclimate.com/github/armandofox/audience1st/maintainability)
![Build Status](https://github.com/armandofox/audience1st/actions/workflows/ci.yml/badge.svg)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f023aeddae42d2da37ba/test_coverage)](https://codeclimate.com/github/armandofox/audience1st/test_coverage)
[![Pivotal Tracker](https://github.com/armandofox/audience1st/blob/main/app/assets/images/pivotal_tracker_logo.png)](https://pivotaltracker.com/n/projects/44802)

Spring 24 Team Badges
[![Maintainability](https://api.codeclimate.com/v1/badges/d9b6e16a95d868605440/maintainability)](https://codeclimate.com/github/cs169/audience1st/maintainability)
![Build Status](https://github.com/cs169/audience1st/actions/workflows/ci.yml/badge.svg)
[![Test Coverage](https://api.codeclimate.com/v1/badges/d9b6e16a95d868605440/test_coverage)](https://codeclimate.com/github/cs169/audience1st/test_coverage)
[![Pivotal Tracker](https://github.com/armandofox/audience1st/blob/main/app/assets/images/pivotal_tracker_logo.png)](https://www.pivotaltracker.com/n/projects/2488109)


Audience1st was written by [Armando Fox](https://github.com/armandofox) with contributions from:
[Abhinav Dhulipala](https://github.com/abhinavDhulipala),
[Xiao Fu](https://github.com/fxdawnn),
[Matthew Fyke](https://github.com/mattfyke),
[Jasper Gan](https://github.com/jasgan),
[CiCi Huang](https://github.com/chengchenghuang),
[Xu Huang](https://github.com/Hexhu),
[Xiaoyu Alan He](https://github.com/AlanHe-Xiaoyu),
[Anthony Jang](https://github.com/segfalut),
[Kyle Khus](https://github.com/kkhus5),
[Wayne Leung](https://github.com/WayneLeung12),
[Autumn Li](https://github.com/autumnli11),
[Yowsean Li](https://github.com/yowsean),
[Anthony Ling](https://github.com/Ant1ng2),
[Jason Lum](https://github.com/jayl109),
[Sanket Padmanabhan](https://github.com/sanketq),
[Andrew Sun](https://github.com/andrewsun98),
[Tanji Saraf-Chavez](https://github.com/tsarafchavez),
[Jack Wan](https://github.com/WanNJ),
[Alex Wang](https://github.com/raisindoc),
[Kevin Yen](https://github.com/crazyberry7),
[Casper Yang](https://github.com/cyang2020),
[Hang (Arthur) Yin](https://github.com/LoserNoOne),
and
[Justin Wong](https://github.com/JustinRWong)


# This information is for developers and deployers

Perhaps you intended to [learn about Audience1st features and/or have us install and host it for you](https://www.audience1st.com)?

You only need the information in this repo and its wiki if you are
deploying and maintaining Audience1st yourself.  If so, the wiki
assumes you are IT-savvy and provides the information needed to help
you get this Rails ~>4 / Ruby ~>2 app deployed.

The high order bits for developers:

* You need Rails ~>4 and Ruby ~>2.

* You need a Stripe account, though you can use just the test-mode keys during development.

* Audience1st is designed for multi-tenancy, and by default uses
Heroku Postgres schemas per tenant.  The wiki includes instructions on
how to make multi-tenancy work with non-Postgres databases or disable
it entirely.

* Audience1st uses Sendgrid to send transactional emails, using
ActionMailer pointed at the Sendgrid SMTP server.  However, you can
easily disable transactional email even in production, so you don't
need a Sendgrid account.

# Want to help with hosting or front-line customer support?

We want to make it appealing for as many small-to-medium-sized
nonprofit theaters as possible to adopt Audience1st.  That involves
customer/tech support, onboarding, and 
many other crucial but nontechnical roles.  Contact me if you want to
help! 

# Want to contribute?  Found a bug?

That'd be great!  I use [Pivotal Tracker
project](https://pivotaltracker.com/projects/44802)  (not GitHub
Issues) to manage the project.  Contact me if you want to help,
there's lots to do.  

1. Fork the repo and make your changes on a branch.

2. Changes must include good comments, 100% test coverage (a
combination of RSpec and Cucumber is fine, but any change that
directly "touches" the UI definitely needs Cucumber scenarios), no net
decrease in code quality/maintainability score on CodeClimate.  The
tests must run and pass in CI.  Cucumber scenarios use PhantomJS for
headless Javascript testing.  There are some Jasmine tests for testing
JavaScript detailed behaviors.

3. Rebase against main and open a pull request.

Questions welcome!
