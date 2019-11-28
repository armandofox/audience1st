BEGIN TRANSACTION;

CREATE TABLE duplicateItemsComments("order_id" INTEGER PRIMARY KEY, "comments" varchar(255));

INSERT INTO duplicateItemsComments
SELECT items.order_id, comments
FROM items 
GROUP BY items.order_id 
ORDER BY items.order_id;

CREATE TABLE items_backup("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "vouchertype_id" integer DEFAULT 0 NOT NULL, "customer_id" integer DEFAULT 0 NOT NULL, "showdate_id" integer, "comments" varchar(255), "fulfillment_needed" boolean DEFAULT 'f' NOT NULL, "promo_code" varchar(255), "processed_by_id" integer DEFAULT 2146722771 NOT NULL, "bundle_id" integer DEFAULT 0 NOT NULL, "checked_in" boolean DEFAULT 'f' NOT NULL, "walkup" boolean DEFAULT 'f' NOT NULL, "amount" float DEFAULT 0.0, "account_code_id" integer, "updated_at" datetime, "letter_sent" datetime, "type" varchar(255), "order_id" integer, "finalized" boolean, "seat" varchar);

INSERT INTO items_backup SELECT items.id, items.vouchertype_id, items.customer_id, items.showdate_id, duplicateItemsComments.comments, items.fulfillment_needed, items.promo_code, items.processed_by_id, items.bundle_id, items.checked_in, items.walkup, items.amount, items.account_code_id, items.updated_at, items.letter_sent, items.type, items.order_id, items.finalized, items.seat
FROM duplicateItemsComments, items
WHERE items.order_id = duplicateItemsComments.order_id
ORDER BY items.id;

DROP TABLE duplicateItemsComments;
DROP TABLE items;

CREATE TABLE "items" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "vouchertype_id" integer DEFAULT 0 NOT NULL, "customer_id" integer DEFAULT 0 NOT NULL, "showdate_id" integer, "comments" varchar(255), "fulfillment_needed" boolean DEFAULT 'f' NOT NULL, "promo_code" varchar(255), "processed_by_id" integer DEFAULT 2146722771 NOT NULL, "bundle_id" integer DEFAULT 0 NOT NULL, "checked_in" boolean DEFAULT 'f' NOT NULL, "walkup" boolean DEFAULT 'f' NOT NULL, "amount" float DEFAULT 0.0, "account_code_id" integer, "updated_at" datetime, "letter_sent" datetime, "type" varchar(255), "order_id" integer, "finalized" boolean, "seat" varchar);

INSERT INTO items_backup SELECT id, vouchertype_id, customer_id, showdate_id, comments, fulfillment_needed, promo_code, processed_by_id, bundle_id, checked_in, walkup, amount, account_code_id, updated_at, letter_sent, type, order_id, finalized, seat
FROM items_backup;

DROP TABLE items_backup;

CREATE TABLE orders_backup ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "customer_id" integer, "purchasemethod" integer, "processed_by_id" integer, "sold_on" datetime, "purchaser_id" integer, "valid_vouchers" text, "donation_data" text, "created_at" datetime, "updated_at" datetime, "walkup" boolean DEFAULT 'f', "ship_to_purchaser" boolean DEFAULT 't', "authorization" varchar(255), "retail_items" text, "external_key" varchar, "ticket_sales_import_id" integer);

INSERT INTO orders_backup SELECT id,customer_id,purchasemethod, processed_by_id, sold_on, purchaser_id, valid_vouchers, donation_data, created_at, updated_at, walkup, ship_to_purchaser, authorization,retail_items, external_key, ticket_sales_import_id FROM orders;

DROP TABLE orders;

CREATE TABLE "orders" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "customer_id" integer, "purchasemethod" integer, "processed_by_id" integer, "sold_on" datetime, "purchaser_id" integer, "valid_vouchers" text, "donation_data" text, "created_at" datetime, "updated_at" datetime, "walkup" boolean DEFAULT 'f', "ship_to_purchaser" boolean DEFAULT 't', "authorization" varchar(255), "retail_items" text, "external_key" varchar, "ticket_sales_import_id" integer);

INSERT INTO orders SELECT id,customer_id,purchasemethod, processed_by_id, sold_on, purchaser_id, valid_vouchers, donation_data, created_at, updated_at, walkup, ship_to_purchaser, authorization,retail_items, external_key, ticket_sales_import_id FROM orders_backup;

DROP TABLE orders_backup;

END TRANSACTION;