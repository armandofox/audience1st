---
layout: page
title: First-Time Setup
category: FirstTimeSetup
date: 2017-11-04T12:23:42.000+00:00
order: "20"

---
The initial deployment of Audience1st contains a single administrative user whose login is `admin@audience1st.com` and password `admin`.

1. **The first thing you should do is login as this user and edit the
   user name and information to match whoever the box office manager or
   operations manager is.**  The Admin privilege is the highest privilege
   and can do anything, so set a good password.  Make sure you are able to
   receive  email at the
   address you give for this user, in case you need to use the "Forgot
   Password" mechanism later to reset your password by email.
2. While still logged in as admin, click the Options tab in the main
   navigation bar to setup [site-wide options including venue
   information]({% post_url 2017-11-04-sitewide-options %}).  
   Some of it
   is necessary before patrons can buy tickets.  (Whoever deployed the site
   for you should have taken care of the necessary steps to connect
   Audience1st to Stripe for payment processing and to MailChimp or
   ConstantContact for sending marketing emails.)

[![questionmark](../assets/video.png)](https://www.youtube.com/watch?v=4PeeZ0km4Ac&list=PLQEw_5c_LyHytBYEpodNlT2cGFExI_iqt&index=16)

3. Next, [create user records]({% post_url 2017-10-28-looking-up-a-customer %}) for additional staff (box office, phone orders, FOH staff, anyone who will need some level of administrative access). To create a user, click the "Add New..." button to the right of the customer search box. This creates the user as a patron. To change their privilege to Staff, Admin, or any other level, click the "Billing/Contact" tab and change the Role setting as appropriate.  A user with Admin privilege can change any other user's privilege level at any time.
4. To import existing customer data, contact Audience1st staff for assistance.