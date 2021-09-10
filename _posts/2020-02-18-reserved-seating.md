---
layout: page
title: Reserved Seating and Seat Maps
category: SeasonSetup
date: 2017-11-03T19:09:42.000+00:00
order: "100"

---
To set up performances with reserved seating, you must set up one or more seat maps.  If your wish to offer different seats at different price points (eg: premium, balcony, obstructed view) or make some seats only available to subscribers, then you will need to create multiple seating zones as well.  You can create as many seating zones as you wish, and you can define multiple seat maps for different configurations (in the round vs. thrust, certain seats removed, etc.)

## Creating seating zones

The system starts out with one pre-defined seating zone called "Regular". If all seats in the venue have the same price points and anyone may reserve any seat, then there is no need to create additional seating zones.

However, you will need to create multiple seating zones if you want different seats to have different price points or if you want some seats to only be available to subscribers or their friends.

To add or edit seating zones, click on the Vouchers tab and click the New Voucher Type button at the bottom of the page. (You only do this to get to the Seating Zones page; you do not need to add a new voucher type at this time.) Click the Add/Edit Seating Zones button next to the "Restrict to seating zone" field. This takes you to the Seating Zones page.

Click the New Seating Zone button to add a new seating zone. You will need to choose a displayed name and a short name for the zone. Patrons will only see the displayed name, while the short name will be used internally on the seat maps you create. You can also set the display order for your seating zones to control the order in which staff will see the zones listed in dropdown menus. Be sure to click the Save button to create your new seating zone.

You may edit or delete an existing seating zone, but you cannot change the short name of a seating zone or delete it altogether if that short name is used in any existing seat maps. Typically you would only edit or delete a seating zone if you made a mistake when initially creating it.

## Create a seat map using a spreadsheet

Use your favorite spreadsheet application, such as Google Sheets or Microsoft Excel, to create a seat map from scratch. The format is simple:

* Each spreadsheet row is a row of seats.  It's conventional, although not required, to orient the seat map so the stage is at the top.
* Each cell provides the seating zone, seat label, and optional accessibility flag for one seat. The cell "reg:A22", for example, indicates a seat  labelled "A22" and belonging to the seating zone whose short name is "reg".  The cell "prem:B101+", meanwhile, indicates that seat B101 is in the seating zone whose short name is "prem" and the seat is accessible (indicated by the plus sign).  Patrons will see the seat labels when they make reservations.  Seat labels can contain uppercase letters and numbers. (Lowercase letters in the spreadsheet cells will simply be converted to uppercase.) Accessible seats will be visually distinguished on the seat map, and the patron will see a reminder that they are booking an accessible seat.
* Leave cells blank to indicate no seat in that cell.  This allows
  representing irregular seat layouts where the seats don't necessarily
  create a perfect rectangular grid.

For some example seat maps, see [this public Google folder](https://drive.google.com/drive/u/0/folders/1apFWPFlGIXhNV8XHHGUQiJjOybyOqa0q).

## Export the seat map as CSV (comma-separated values)

When you have finished creating the seat map in your spreadsheet application, save it as a CSV file.  All spreadsheet programs have a way to save this common format.  (If your spreadsheet program offers a choice that specifically says "MS-DOS comma-separated values", use that choice.)

## Upload the spreadsheet into Audience1st

Use the Add/Edit Seatmaps page to upload your spreadsheet into Audience1st. To get to this page, click the Seasons tab, click on any show, click the Add Performances button, and then click the Add/Edit Seatmaps button that appears next to the Seat Map field.

On the seat maps page, click on the Choose File button and select the CSV file that you saved from your spreadsheet application. Then enter a name for your seat map in the "Name for new seatmap" field. Only theater staff, and not patrons, will be able to see the names of seat maps. You should choose a name that is descriptive so that it will be easy to differentiate seat maps from each other by name. Click the Upload button to create the seat map in Audience1st.

Each seat in the seat map must have a valid seating zone short name and a unique label. For example, your seat map cannot have two seats with the same label "A101", and a seat cannot be in seating zone "balc" if no such seating zone has already been created in Audience1st.

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

## Editing, previewing, and duplicating seat maps 

On the Add/Edit Seatmaps page, you can edit the name or background image of an existing seat map by clicking the Edit button next to the particular seat map. If the seat map has not yet been used in any performances, you'll also be able to delete the seat map altogether. You can also see what the seat map will look like by clicking the Preview button.

If you want to duplicate an existing seat map so that you can make some minor changes (perhaps you will remove a few seats for one production and put them back in later) you can click the Download CSV button next to the existing seat map. You can then load this CSV file into your spreadsheet software, edit as desired, save a new CSV file, and upload this file into Audience1st as a new seat map.

## Restricting tickets to specific seating zones

By default, any valid voucher for a performance can be used to reserve any available seat in the house. If your seat map has multiple seating zones, you probably do not want seat reservations to work this way. Use the "Restrict to seating zone" field on voucher types to limit vouchers of this type to one zone only. 

Suppose your theater has Premium and Regular seating zones. You might create a single ticket voucher type called "Premium adult" that allows the buyer to reserve any seat in the house. On this voucher type you would leave the "Restrict to seating zone" field set to its default value of "No restriction". You  might also create a single ticket voucher type called "Regular adult" that has a lower price but only allows the buyer to reserve seats in the "Regular" seating zone. On this voucher type you would set the "Restrict to seating zone" field to "Regular".

Seating zone restrictions can be placed on single tickets, comps, and items in a subscription or bundle. This allows you sell single tickets at different price points as seen in the example above, as well as offer comps that are only good for certain seats and also offer differently priced subscriptions based on what seats can be reserved by the subscriber.

When a patron reserves a seat using a voucher that has a seating zone restriction, the seat map will show all seats in other zones as unavailable. Theater staff can override zone restrictions and upgrade a patron as needed.

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

During seat selection, hovering over any seat shows its seating zone and label, and clicking on a seat selects or un-selects it.  If the patron selects an accessible seat, a pop-up appears asking them to ensure they really need the accommodation.  You can change the wording of this pop-up on the \[Options screen\]({% post_url 2017-11-04-sitewide-options %}).