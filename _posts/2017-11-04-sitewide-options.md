---
layout: page
title: Site-Wide Options
category: FirstTimeSetup
date: 2017-11-04T12:36:34.000+00:00
order: "29"

---
Audience1st has a variety of site-wide options you can set; most of them
will only be set once, but some you may find useful to change
periodically.
All can be found by clicking the Options tab on the main navbar (you
must be logged in as Box Office Manager or higher to see this tab).

Hover over (or tap on a mobile device) the question mark icon ![questionmark](../assets/question.png) next to each setting on that
screen for more
information about what that setting controls.

**Important:** You must click the Save button at the bottom of the
screen for your changes to take effect.  They will typically take effect
within a few minutes.

Some options allow the use of HTML-formatted text.  The HTML will be
"sanitized" to remove dangerous tags and attributes, such as
`<script>` tags, `javascript:` handlers, and so on.  In addition,
for option text that includes links (`<a>` elements), the use of
`target="_blank"` to open the link in a new window will be sanitized
because it is a security vulnerability: instead, use
`class="new-window"` on such elements to get the same effect.

Most of the options are self-explanatory, but a few that deserve
special mention are the ones at the bottom under "Integrations".
These are important options and you must explicitly click "Allow
Changes" before you can edit them:

## Stripe Key and Stripe Secret

Replace these with the **live mode** (not "test mode") key and secret
in your Stripe.com account.

## Stylesheet URL

If you leave this blank, Audience1st will display using its standard,
nondescript visual styling.

However, you can
[customize the appearance]({% post_url 2020-02-09-css-styling %}) of all
Audience1st patron-facing screens using Cascading Style Sheets.  To do so,
create your stylesheet, post it somewhere publicly available and accessible via
a Secure HTTP (`https`) URL, and enter that URL here.  Here are suggestions for
where to store your CSS page free of charge:

* If your theater's separate website has a static content area (for example,
  WordPress-based sites have directories from which static assets such as images
  are publicly served), host the file there
* Host it in a public repository on GitHub or GitLab, and use a service such as
  [JSdelivr](https://jsdelivr.net) to serve it directly from there
* Host it on [Netlify](https://netlify.com) and serve from there

Note that when you update your stylesheet, depending on how it is hosted, it may
take a few minutes for the changes to propagate.

## Mailchimp Key and Mailchimp Default List Name

If you use Mailchimp, you can have the results of customer reports
exported there for email marketing campaigns.  See the [Mailchimp
Integration]({% post_url 2020-02-10-mailchimp %}) article for help.

## Staff Access Only

Once you change this to "No", your Audience1st site will be accessible
to the world.  "Yes" means only staff members can login.

## Sender Domain

This setting controls the return address on transactional emails sent to patrons, such as purchase confirmations. Don't change this unless you plan to use a different email provider setup than the one provided by Audience1st. Audience1st includes a "Reply to" address in transactional emails so that if a patron replies to one of these emails, the reply will be sent to your box office.