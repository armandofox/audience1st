---
layout: page
title: "First-Time Setup"
category: intro
date: 2017-11-04 12:23:42
order: 20
---

The initial deployment of Audience1st contains a single administrative user whose login is `admin@audience1st.com` and password `admin`.  

0. **The first thing you should do is login as this user and edit the user name and information to match whoever the box office manager or operations manager is.**  The Admin privilege is the highest privilege and can do anything, so set a good password.

0. While still logged in as admin, click the Options tab in the main navigation bar.  Fill in the information about your venue.  Some of it is necessary before patrons can buy tickets.  (Whoever deployed the site for you should have taken care of the necessary steps to connect Audience1st to Stripe for payment processing and to MailChimp or ConstantContact for sending marketing emails.  If not, direct that person to the Integrations section of this guide.)

0. Next, create user records for additional staff (box office, phone orders, FOH staff, anyone who will need some level of administrative access).  See "Working with users" for how to do this.  Edit each user's Billing/Contact info, and under Admin settings for that user, set their privilege level as appropriate (you can always change it later).

0. To import existing customer data, click the Import tab.  (Description TBD as this feature is under refurbishment)
