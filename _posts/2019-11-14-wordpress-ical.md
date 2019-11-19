---
layout: page
title: "Show Calendar"
category: IntegrationWithYourWebsite
date: 2017-11-23 16:45:26
order: 30
---

You can display a month-at-a-time, week-at-a-time, or other calendar
view on your WordPress-based website by using any WordPress plugin
that can consume and display a calendar feed in "ICS" or "iCalendar"
format.

We recommend the **ICS Calendar** plugin from Room34 Designs.  It is
free to install and use, or you can upgrade to the Pro version that
has additional features.  The free version displays events from one or
more feeds, but does not allow you to manually create one-off events
(for example, a party or fundraiser that is not also listed as an
event in Audience1st).

**The Events Calendar** from Modern Tribe
allows you to both create events manually and import events from an
external source, but you must pay for the Pro version (about $89/year)
for the ability to import.

## Using the ICS Calendar plug-in

To install and configure the free version of ICS Calendar:

1. In your WordPress Dashboard, select Plugins > Add New, and search
for the "ICS Calendar" plugin.  Install it and activate it.

2. Configure the settings for ICS Calendar however you like.

3. To insert a calendar display on a page or page component, use the
following "shortcode":

`[ics_calendar url="http://`_your-theater-name_`.audience1st.com/ics/showdates.ics" title="Show Calendar" eventdesc="true" linktitles="true" view="month" toggle="true"]`

You can change the value of the `title` attribute to whatever title
you want to appear above the calendar.

`linktitles="true"` means that the name of each show (performance) in
the calendar, when clicked, will take the customer to the Audience1st
store page pre-filled to get tickets for that performance.  If you
omit this, the link will not be clickable.

`eventdesc="true"` shows the brief description of the show (as entered
on the "Show Details" page for that show in Audience1st) as part of
the calendar entry when hovered over.  Omit this to display only the
show name with no description.

See the ICS Calendar Settings within your WordPress dashboard for
other options and views and to change its visual styling (fonts,
colors, etc.)

## Using The Events Calendar plug-in

To install and configure the Pro version of The Events Calendar (Pro
version is required for importing and displaying the Audience1st
feed):

(Instructions TBD)
