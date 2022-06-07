---
layout: page
title: "Customizing Transacational/Confirmation Emails"
category: Customizing
order: 100
---

The visual theming (colors, fonts, layout, and so forth) of all
patron-facing screens and some of the admin-facing screens can be
controlled using Cascading Style Sheets version 3 (CSS3).  This
article assumes that the person doing the work is familiar with 
CSS3, and that you have [set up in the Options screen]({% post_url
2017-11-04-sitewide-options %}) the public HTTPS URL of the
stylesheet.

**NOTE:** The CSS stylesheet **must** be served from an `https` URL.
Depending on the caching behavior of the server that serves the page
and the caching settings on users' browsers, it may take up to 24
hours for all users to see the change.

Audience1st uses [Bootstrap](https://getbootstrap.com) version 4, so
you can assume all Bootstrap CSS classes are loaded.

The following are the aspects of the site that can be easily themed.
The venue's style sheet is loaded last, so in addition to the below,
you can in principle override the styles used for the admin pages,
though that might mess up the layout.


## Confirmation emails and other transactional emails

Confirmation-transaction emails (orders, reservations, account profile
changes, etc.) are delivered as HTML.  On the Options screen, you can
upload an HTML template to use for such emails that has the following
properties:

* It should be a well-formed HTML 5 document including the opening
`<!DOCTYPE html>` declaration.

* Any CSS style information should be embedded in the document itself
using the `<style>` element.

* The template *must* contain exactly one instance of the string
`=+MESSAGE+=`, which will be replaced by the specific message contents
(order confirmation details, etc.) when the email is sent.
The body portion of the email will be inside an element
`div.a1-email`.  The examples below show what elements are present in
specific transactional emails.

* The template *may* contain exacty one instance of the string
`=+FOOTER+=`, which if present will be replaced by some basic
information (inside a `div.a1-footer` element)
about how to contact the theater in case of questions, based on the
information filled in on the Options screen.
If this string is absent, the template is assumed to already include
this information.

# Specific elements on the main ticket sales page `#store_index`

* `#show_description` styles the specific notes/description associated
with the production

* `#showdate_long_description` styles the block of text associated
with the long description, if any, of the specific performance

* `#ticket-types` is the container that contains all the dropdown
menus for selecting the quantity of each ticket type to purchase

* `#orderTotal` is the container displaying the total order amount as
tickets get added to the order.  Within it, there is a `<label>`
element that styles the phrase **Order Total** and a `#total` input
field that styles the amount of the order.
