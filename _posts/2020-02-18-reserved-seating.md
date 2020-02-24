---
layout: page
title: "Reserved Seating and Seat Maps"
category: SeasonSetup
date: 2017-11-03 19:09:42
order: 100
---

To set up performances with reserved seating, you must set up one or
more seat maps.  You can define multiple seat maps for different
configurations (in the round vs. thrust, certain seats removed, etc.)

There is no concept of seating "zones" (such as Regular vs Premium),
but there are ways to differentiate pricing for seats in other ways,
as the second part of this article shows.

**Note:**  Setting up seat maps and selling reserved seating tickets
is the easy part.  There are many box office workflows required to
support reserved seating that are absent for general admission.
Before setting up reserved seating, be sure you have resourced and
rehearsed those workflows.

TBD: Link to a document with suggested outline for migrating to
reserved seating.

## Create a seat map using a spreadsheet

The first step is to create a seat map using your favorite
spreadsheet, such as Google Sheets or Microsoft Excel.
The format is simple:

* Each spreadsheet row is a row of seats.  It's conventional to
present the seat map so the stage is at the top.

* Each spreadsheet is a cell containing a seat label, such as "A1",
"D22", etc.  These are the labels patrons will see when they make
reservations.  Seat labels can contain uppercase letters and numbers, and can
terminate in an optional "+" to indicate an accessible seat.
(Lowercase letters in the spreadsheet cells will simply be converted
to uppercase.)
Accessible seats will be visually distinguished on the seat map, and
the patron will see a reminder that they are booking an accessible seat.

* Leave cells blank to indicate no seat in that cell.  This allows
representing irregular seat layouts where the seats don't necessarily
create a perfect rectangular grid.

For some example seat maps, see [this public Google folder](https://drive.google.com/drive/u/0/folders/1apFWPFlGIXhNV8XHHGUQiJjOybyOqa0q).

## Export the seat map as CSV (comma-separated values)

When the seat map is ready, save it  as a CSV file.  All spreadsheet
programs have a way to save this common format.  (If your spreadsheet
program offers a choice that specifically says "MS-DOS comma-separated
values", use that choice.)

## Optional but highly recommended: Seat map background image

When the patron is choosing seats, the seat map will be overlaid on top
of an optional background image, which can label the aisles, show
where the stage is, or include other decorative or informative
background elements.  Each seat map has its own background image,
though you can certainly use the same image for all seat maps.

The seat map can be created in any drawing program and saved as PNG
(preferable), SVG, GIF (if necessary, though PNG is a more portable
format), or JPG (not recommended).  
Essentially, the image's aspect ratio must match that of the seat map as determined
by counting rows and columns.  For example, if your seat map has 20
rows (counting the topmost and bottommost spreadsheet rows that have any number of
seats) and the longest row has 10 seats (counting the leftmost and
rightmost spreadsheet columns that have labels in any row), your seat
map's aspect ratio is 20/10 or 2.0.  So the background image should be
exactly twice as wide as it is high.  The actual number of pixels
doesn't matter, as Audience1st will scale it to fit behind the seat map.
Here is an
[example](https://drive.google.com/open?id=1sX6Hl3Y9dqBwJEyzA8UzPMESyO3fg9toX_DLMX25jsk)
of a seat map background image with instructions on how to adapt it
for your own use.

## Differentiated access to reserved seats

Audience1st does not distinguish seating zones with different prices
per seat, but it can differentiate pricing based on redemptions.  That
is, earlier buyers get access to better seats but may pay more.

For example, you could [create two redemptions]({% post_url
2017-11-03-setting-up-redemptions %}) (using two different
voucher types with different prices, say
"Regular" and "Preferred") for the same performance.
The redemption for "Preferred" vouchers goes on sale immediately,
while "Regular" goes on sale later.  In effect, earlier buyers (who
are willing to pay more) get the best choice of seats.

(Some theaters do "dynamic pricing" in which ticket prices rise as
more seats are sold.  Audience1st doesn't support this, and we think
it's a bad idea, since someone who was on the fence about seeing the
show at $30 is not likely to suddenly get excited to pay $40.)

## Reserved seating during sales flows

When a performance is RS, every flow that involves allocating
seats introduces an additional seat-selection step.  These flows are:

1. The general patron-facing sales flow.  Once the patron has selected
ticket types and quantities, they must select the correct number of
seats before continuing to checkout.

2. A subscriber making reservations against their subscriber vouchers.

3. A box office agent adding comps, if the comp is to be reserved
immediately for a particular performance.

4. A box office agent selling tickets to walk-up customers
without reservations.

5. A box office agent importing a will-call list from a third-party
vendor such as Goldstar or TodayTix.

During seat selection, hovering over any seat shows its seat number,
and clicking on a seat selects or un-selects it.  If the patron
selects an accessible seat, a pop-up appears asking them to ensure
they really need the accommodation.  You can change the wording of
this pop-up on the [Options screen]({% post_url
2017-11-04-sitewide-options %}).
