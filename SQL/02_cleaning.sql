-- Data quality checks and cleaning

-- Orders marked as 'delivered' without a delivery date
SELECT order_id, order_status, order_approved_at, order_delivered_carrier_date,
 order_delivered_customer_date, order_estimated_delivery_date FROM orders
WHERE order_delivered_customer_date IS NULL AND order_status = 'delivered';
-- Result: 8 orders
-- All of them have an approval date and an estimated delivery date, and 7 out of 8 
-- were handed to the carrier. Hence, the delivery most likely happened, 
-- but its date was not recorded.
-- Decision: keep these orders and exclude them only from delivery time analyses.

-- Products without a category 
SELECT product_id, product_category_name FROM products
WHERE product_category_name IS NULL;
-- Result: 610 products
-- Decision: assign them the category 'unknown'. 'unknown' is also added to category_translation.

INSERT INTO category_translation (product_category_name, product_category_name_english)
VALUES ('unknown', 'unknown');

UPDATE products
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;

-- Categories of products that do not exist in category_translation
SELECT p.product_category_name FROM products p 
LEFT JOIN category_translation c ON p.product_category_name = c.product_category_name
WHERE c.product_category_name IS NULL AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name;
-- Result: 2 categories
-- Decision: add the 2 missing translations

INSERT INTO category_translation (product_category_name, product_category_name_english)
VALUES ('pc_gamer', 'pc_gamer'), 
('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_preparers');


-- Orders whose delivery date is before the purchase date
SELECT order_id, order_purchase_timestamp, order_delivered_customer_date FROM orders
WHERE order_purchase_timestamp > order_delivered_customer_date;
-- Result: 0 orders (no inconsistencies)

-- Payments with a value of zero or less
SELECT order_id, payment_type, payment_value FROM order_payments
WHERE payment_value <=0;
-- Result: 9 payments, all with value 0

-- Orders with a price of zero or less
SELECT order_id, product_id, price FROM order_items
WHERE price <= 0;
-- Result: 0 items (no inconsistencies)

-- Duplicated review_id
SELECT review_id FROM order_reviews
GROUP BY review_id 
HAVING COUNT(*)>1;
-- Result: 789 review_ids appear more than once
SELECT * FROM order_reviews
WHERE review_id IN (
    SELECT review_id FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
    LIMIT 3
)
ORDER BY review_id;
-- The same review (same score, comment and dates) is linked to different orders
-- Decision: legitimate data, no changes needed.


-- Orders with more than one review
SELECT order_id FROM order_reviews
GROUP BY order_id
HAVING COUNT(*)>1;
-- Result: 547 orders
SELECT * FROM order_reviews
WHERE order_id IN (
    SELECT order_id FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
    LIMIT 3
)
ORDER BY order_id;
-- These orders received different reviews (different scores and dates).
-- Decision: keep all reviews. In the analyses, reviews will be reduced to
-- one row per order (average score) before joining them with orders.

-- Rows of geolocation for every zip code prefix
SELECT geolocation_zip_code_prefix, COUNT(*) FROM geolocation
GROUP BY geolocation_zip_code_prefix;
-- Result: 19,015 zip code prefixes
-- Decision: create a new table with one row per zip code prefix,
-- using the average latitude and longitude.

CREATE TABLE geolocation_zip AS
SELECT geolocation_zip_code_prefix,
       AVG(geolocation_lat) AS lat,     
       AVG(geolocation_lng) AS lng
FROM geolocation
GROUP BY geolocation_zip_code_prefix;


-- Payments equal to zero or not_defined
SELECT order_id, payment_sequential, payment_type, payment_value FROM order_payments
WHERE payment_type='not_defined' OR payment_value=0;
-- Result: 9 payments, all with value 0 
-- Decision: kept all the records

ALTER TABLE orders ADD CONSTRAINT fk_orders_customer_id
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id);

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_order_id
    FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_product_id
    FOREIGN KEY (product_id) REFERENCES products (product_id);

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_seller_id
    FOREIGN KEY (seller_id) REFERENCES sellers (seller_id);

ALTER TABLE order_payments ADD CONSTRAINT fk_order_payments_order_id
    FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE order_reviews ADD CONSTRAINT fk_order_reviews_order_id
    FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE products ADD CONSTRAINT fk_products_category
    FOREIGN KEY (product_category_name)
    REFERENCES category_translation (product_category_name);