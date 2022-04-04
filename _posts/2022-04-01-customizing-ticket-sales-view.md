---
layout: page
title: "Customizing Ticket Sales View"
category: Customizing
order: 200
---

**WARNING:** Use these advanced features at your own risk, since they
affect the patron-visible layout and behavior of Audience1st in ways
that we cannot override!

This explanation assumes you already know how to [author and host the
Audience1st CSS file]({% post_url 2020-02-09-css-stylind %}).

Using CSS, you can selectively show or hide specific ticket types at
purchase time, based on whether the ticket type requires a promo code
or not.

The relevant structure of the ticket page is as follows.  There is an
outer wrapper `ticket-menus-outer` and an inner wrapper
`ticket-types`, both of which have CSS classes identifying the show
and showdate ID,
and finally a set of `form-group` wrappers, one for each ticket type
that can be purchased for that performance.

```html
<div id="ticket-menus-outer" class="show-35 showdate-251">
  ...
  <div id="ticket-types"  class="show-35 showdate-251">
    <div class="form-group form-row promo vouchertype_809">
       <!-- code that allows selecting tickets of this type -->
    </div>
    <div class="form-group form-row no-promo vouchertype_810">
       <!-- code that allows selecting tickets of this type -->
    </div>
    <!-- etc -->
  </div>
</div>
```

In the above example, vouchertype ID 809 is visible only because the
patron entered a promo code.

If the patron has entered a promo code (whether valid or not for this
performance), the class `with-promo`

