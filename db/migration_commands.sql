BEGIN TRANSACTION;

CREATE TEMPORARY TABLE backup(id,customer_id,purchasemethod, processed_by_id, sold_on, purchaser_id, valid_vouchers, donation_data, created_at, updated_at, walkup, ship_to_purchaser, authorization,retail_items, external_key, ticket_sales_import_id);

INSERT INTO backup SELECT id,customer_id,purchasemethod, processed_by_id, sold_on, purchaser_id, valid_vouchers, donation_data, created_at, updated_at, walkup, ship_to_purchaser, authorization,retail_items, external_key, ticket_sales_import_id FROM orders;

DROP TABLE orders;

CREATE TABLE orders(id,customer_id,purchasemethod, processed_by_id, sold_on, purchaser_id, valid_vouchers, donation_data, created_at, updated_at, walkup, ship_to_purchaser, authorization,retail_items, external_key, ticket_sales_import_id);

INSERT INTO orders SELECT id,customer_id,purchasemethod, processed_by_id, sold_on, purchaser_id, valid_vouchers, donation_data, created_at, updated_at, walkup, ship_to_purchaser, authorization,retail_items, external_key, ticket_sales_import_id FROM backup;

DROP TABLE backup;