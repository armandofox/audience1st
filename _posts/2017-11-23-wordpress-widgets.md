---
layout: page
title: "Real-Time Ticket Availability Thermometer"
category: IntegrationWithYourWebsite
date: 2017-11-23 16:45:26
order: 30
---

[Ticket
Availability](https://wordpress.org/plugins/audience1st-ticket-availability)
is a WordPress plug-in that
shows a thermometer-like view of ticket availability for upcoming
performances (you select how many, and set some other options, by
logging in to your WordPress administration console and selecting the
Audience1st Ticket Availability submenu under Settings in the left-hand
navbar). 

![ticket availability widget](../assets/ticket-widget.png)

## Installation

Log in to your WordPress installation as an administrator, and in the
left-hand nav bar select Plugins, then Add New Plugin.

Search for "Audience1st Ticket Availability" and it should be found in
the public WordPress plugins directory.

Click "Install" to install, then "Activate Plugin" to activate it.

Once the plugin is installed, in the WordPress navbar select
Settings > Audience1st Ticket Availability.

Fill in the "base URL" of your theater's Audience1st installation, as
in `http://my-theater.audience1st.com`.

Fill in the maximum number of upcoming performances for which the
plugin should display availability information.

## To change the thresholds for Excellent, Good, and Limited

4. In Audience1st, go to the Options screen and you can set the
thresholds for "Excellent", "Good", and "Limited" availability.

## To change the styling of the thermometer (advanced users)

In the WordPress navbar, select Plugins > Plugin Editor and choose
this plugin.  You should now be able to see the contents of the file
`style.css` in the plugin's directory.  This gives you the classes of
all the HTML elements used in the plugin; you can override these in
your top-level CSS file.


