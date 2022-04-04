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
Audience1st CSS file]({% post_url 2020-02-09-css-styling %}).

Using CSS, you can selectively show or hide specific ticket types at
purchase time, based on whether the ticket type requires a promo code
or not.

The relevant structure of the ticket page is as follows.
The container
`ticket-types` has CSS classes identifying the show
and showdate ID.
Inside that container is a set of `form-group` wrappers, one for each ticket type
that can be purchased for that performance:

```html
<div id="ticket-types" class="show-35 showdate-251">
  <div class="form-group form-row no-promo vouchertype_810">
     <!-- code that allows selecting tickets of this type -->
  </div>
  <!-- similar form-groups for other ticket types -->
</div>
```
In the above example, the class `no-promo` indicates that this ticket
type does **not** require entering a promo code to see.

Suppose there is a ticket type whose internal ID is 809 and is visible
only if the promo code `JETS` is entered.  When the patron enters that
promo code, the class `with-promo` and the attribute
`data-promo="JETS"` will be added to the `ticket-types` container, and the ticket
types that have become newly visible due to the promo code (809 in the
example below) will have the class `promo` added to their form-group:

```html
<div id="ticket-types" class="show-35 showdate-251 with-promo" data-promo="JETS">
  <div class="form-group form-row promo vouchertype_809">
     <!-- code that allows selecting tickets of this type -->
  </div>
  <div class="form-group form-row no-promo vouchertype_810">
     <!-- code that allows selecting tickets of this type -->
  </div>
  <!-- similar form-groups for other ticket types -->
</div>
```

Therefore, the following CSS rule would **hide** all non-promotional
ticket types, **provided** a promo code has actually been entered:

```css
#ticket-types.with-promo  .no-promo  {
  display: none;
}
```

**Notes:**

* If the patron has not entered a promo code, the `.with-promo` class
would be absent, so the selector would not apply.

* Similarly, _without_ the qualifier `.with-promo` on `#ticket-types`, the
hiding of non-promo tickets would happen even if **no** promo code had
been entered, meaning no tickets would be visible at all.

To implement this same behavior but only for specific shows--for
example, show ID 9 and 10, but not other shows:

```css
#ticket-types.with-promo.show-9  .no-promo,
#ticket-types.with-promo.show-10 .no-promo   {
  display: none;
}
```

To implement it at the per-performance level, you can qualify the selectors
with `.showdate-NNN` rather than `.show-NNN`.

**WARNING.** If you use this functionality and a patron enters an
invalid promo code, `with-promo` will still be present and
`data-promo` will still be set to the invalid promo code, so such
selectors would still apply.  **This means a patron who enters a
nonexistent promo code may see no tickets at all,** and would need to
"clean reload" the ticket sales page (by going to
`venuename.audience1st.com/store` directly) to reset the view.

