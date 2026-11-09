CREATE VIEW vw_orders AS 
WITH reviews_per_order AS (
    SELECT order_id, ROUND(AVG(review_score),2) AS avg_rev_score FROM order_reviews
GROUP BY order_id
),
items_per_order AS (
SELECT order_id, COUNT(order_item_id) AS n_items, SUM(price) AS items_value,
SUM(freight_value) AS freight_value FROM order_items
GROUP BY order_id
)
SELECT o.order_id, 
       o.order_status, 
       o.order_purchase_timestamp,
       c.customer_unique_id, 
       c.customer_state, 
       o.order_delivered_customer_date::date - o.order_purchase_timestamp::date AS delivery_days,
       CASE WHEN o.order_delivered_customer_date IS NULL THEN NULL
            WHEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date THEN 1 
            ELSE 0 END AS is_late,
        r.avg_rev_score,
        i.n_items,
        i.items_value,
        i.freight_value
    FROM orders o 
INNER JOIN customers c
ON c.customer_id = o.customer_id
LEFT JOIN items_per_order i ON i.order_id = o.order_id
LEFT JOIN reviews_per_order r ON r.order_id = o.order_id; 

SELECT * FROM vw_orders;

CREATE VIEW vw_order_items AS
SELECT o.order_id, 
       i.order_item_id,
       p.product_id,
       ct.product_category_name_english AS category,
       i.price,
       i.freight_value,
       s.seller_state,
       o.order_purchase_timestamp,
       o.order_status FROM orders o 
INNER JOIN order_items i ON i.order_id = o.order_id
INNER JOIN products p ON p.product_id = i.product_id
INNER JOIN sellers s ON s.seller_id = i.seller_id
INNER JOIN category_translation ct ON ct.product_category_name = p.product_category_name;

SELECT * FROM vw_order_items;
