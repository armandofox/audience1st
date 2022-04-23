---
layout: page
title: Importing External Vendor Will-Call Lists
category: FrontOfHouse
date: 2017-11-03T18:57:37.000+00:00
order: "100"

---
Audience1st integrates with multiple third party ticket selling vendors so that your theater can have a unified check-in, door list, and reporting experience even if tickets to performances are sold through multiple sales channels. At this time Audience1st integrates with Goldstar and TodayTix. If your theater works with a different sales vendor, let us know and we may be able to add support for your vendor to Audience1st.

After importing an external vendor's will-call list, patrons who bought their tickets through the vendor will appear on the door list and the front of house check in screen in much the same way as patrons who bought their tickets through Audience1st. Patrons who already had an Audience1st account and then purchased tickets through the external vendor will see their external vendor purchase alongside their Audience1st purchases when they log into their Audience1st account. All Audience1st reports include the tickets sold by external vendors.

Importing external vendor will-call lists into Audience1st makes the check in process easier because theater staff do not need to consult multiple door lists. Also, the theater gets a better understanding of patron activity because all reports include both Audience1st and external vendor ticketing activity.

To import a will-call list from an external vendor you will need to set up new voucher types in Audience1st, locate the will-call list provided by the external vendor in a suitable format, and access the Import tab to bring the will-call list into Audience1st. We'll look at these steps one at a time.

## Setting Up New Voucher Types for External Vendors

Create one new voucher type for each price point used by your external vendor. The price of the voucher type in Audience1st must match the external vendor's price exactly. In addition, the name of the voucher type must include the external vendor's name. Finally, the availability for the voucher type must be set to "Sold by external reseller".

For example, suppose you have signed up with Goldstar to sell half price tickets to your performance for $20 each, and also to give away a few free tickets to the performance as well. You would need to create two new voucher types in Audience1st. The first would be a regular revenue (single ticket) with a price of $20 and perhaps a name of "Goldstar half price". The second would be a comp (single ticket) and could have a name such as "Goldstar free ticket". Both voucher types would have their availability set to "Sold by external reseller".

As with all voucher types, you also must create redemptions for these new voucher types. That is, you must tell Audience1st at which performances these voucher types may be redeemed. To do this quickly and easily, click on the Season tab and then click on the show. Next click on the "Add/Change Ticket Redemptions" button. On the next page, select all of the external vendor voucher types just created, select all of the performances where they will be honored, and click the Apply Changes button.

You can call these special voucher types anything you wish, as long as they contain the external vendor's name somewhere in their name. The matching will not be case sensitive, so you could, for example, include TodayTix, todaytix, or TODAYTIX in a voucher type name for use with TodayTix. Patrons will never see these voucher type names, but they will appear on door lists and the check in screen in the Front of House tab.

## Locate Will-Call List Provided by External Vendor

Your external vendor will send you an email shortly before the house opens prior to the performance. This email will include the will-call list in many forms. The names of the patrons may appear in the body of the email as plain text. They may also be listed in a PDF file  attached to the email. The information is also provided in machine-readable formats as well.

Emails from Goldstar will include a link to download a JSON file. Click the link to download the JSON file. You will use this file to import the will-call list into Audience1st in the next step. Emails from TodayTix, meanwhile, will include an attached file with a name that ends in ".csv". You will use this file to import the will-call list into Audience1st in the next step.

## Bring the Will-Call List into Audience1st

To load the will-call list from your external vendor into Audience1st, log into Audience1st as a box office manager or administrator and click the Import tab. Select the external vendor whose will-call list you wish to import, choose the will-call file you located in the previous step, and click the Upload button.

Audience1st will now list the contents of the will-call list. For each ticketing transaction in the list, Audience1st will display the external vendor's order number, when the customer made their purchase, how many tickets purchased and what type, the customer's name, and their email address if provided. Audience1st will attempt to match the customer listed in the will-call list with an existing Audience1st patron record based on email address if provided or else by name. If a possible match is found, Audience1st will provide the name, email address, and mailing address of the possible match. The option to create a new patron record will also be provided.

A countdown timer will appear at the top of the page. You will have a limited amount of time, 15 minutes is the default, to complete the processing of the import. If you do not finish in time, the import process will cancel and you will need to start all over. (Any patron name matches and seat assignments you have entered will be lost.) If you find that the allotted time is too short, you can lengthen it on the Options tab. The reason your time is limited to complete an import is that while you are working with the import file, you are tying up resources. If you select a seat for a patron, that seat is not available to anyone else. If you were to accidentally close your browser tab or otherwise leave the import process without completing it, those seats would be unavailable indefinitely if there were not a time limit on the import process. 

Go through all of the will-call list transactions and for each one that includes a possible match to an existing patron record, decide whether to use the existing patron record or create a new one. If you are in doubt, opt to create a new patron record. It would be better to have a patron in your system twice than to have one patron record that includes ticket activity for multiple unrelated people. If you discover later that a patron does have duplicate patron records in Audience1st, tools are available to merge them together.

If the performance uses reserved seating, you will also need to choose seats for each entry in the will-call list. Simply click the "Choose seats" button on one transaction, note the number and type of tickets sold, choose the desired seats in the usual way, and then click the Confirm button to confirm this customer's seats. 

After you have reviewed the patron record matches for each purchase and decided which purchases will generate new patron records and which will use existing patron records, and after you have assigned seats to all tickets if the performance uses reserved seating, click the Import button at the bottom of the page. New patron records will be created as needed, an order will be created in Audience1st for each transaction identified by the external vendor, and seats will be assigned if the performance uses reserved seating.

From this point forward, these patron records, tickets, and reservations will work the same way as if the sale had been made through Audience1st. You can check in a patron, change their seats, view their history, and so forth all in the usual way. You may also return to the Import tab at any time to review the results of a particular will-call list import from the past.

Note that Audience1st determines which performance the external vendor's will-call list is for by matching the curtain time and not the show's name. Therefore, it is imperative that you provide the external vendor with the correct curtain time for the performance.