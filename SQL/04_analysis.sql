-- Business questions on the Olist dataset.
-- All analyses consider only delivered orders.
-- Revenue = sum of item prices (freight excluded).


-- 1. What are the total revenue, number of orders and number of unique customers?
SELECT SUM(items_value)                   AS tot_rev,
       COUNT(order_id)                    AS num_ord,
       COUNT(DISTINCT customer_unique_id) AS num_cust
FROM vw_orders
WHERE order_status = 'delivered';
-- Result: total revenue = 13,221,498.11, number of orders = 96,478,
-- number of unique customers = 93,358.


-- 2. What is the Average Order Value (AOV) and the average number of items per order?
SELECT ROUND(AVG(items_value), 2) AS AOV,
       ROUND(AVG(n_items), 2)     AS avg_num_items_per_order
FROM vw_orders
WHERE order_status = 'delivered';
-- Result: average order value = 137.04, average number of items per order = 1.14.


-- 3. How do revenue and number of orders evolve month by month?
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       ROUND(SUM(items_value), 2)                          AS rev,
       COUNT(order_id)                                     AS num_orders
FROM vw_orders
WHERE order_status = 'delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;
-- Result: 23 months, from September 2016 to August 2018.
-- - The first months of 2016 have very few orders (1 in September,
--   1 in December, none in November): the data for this period is
--   incomplete, so it is not representative.
-- - From 2017 the business grows: revenue goes from about 112k in January 2017
--   to over 900k in early 2018.
-- - The highest peak is in November 2017 (7,289 orders, ~988k revenue),
--   probably due to Black Friday.


-- 4. Which product categories sell the most items?
SELECT category,
       COUNT(*) AS num_items
FROM vw_order_items
WHERE order_status = 'delivered'
GROUP BY category
ORDER BY num_items DESC
LIMIT 10;
-- Result: the top 3 categories are bed_bath_table (10,953 items),
-- health_beauty (9,465) and sports_leisure (8,431).
-- 3 of the top 10 categories are related to the home
-- (bed_bath_table, furniture_decor, housewares).


-- 5. Which product categories generate the highest revenue?
SELECT category,
       SUM(price) AS rev
FROM vw_order_items
WHERE order_status = 'delivered'
GROUP BY category
ORDER BY rev DESC
LIMIT 10;
-- Result: health_beauty is first in revenue (~1.23M) and second in items sold.
-- watches_gifts sells fewer items (7th place) but is 2nd in revenue (~1.17M):
-- its products are expensive (~199 per item on average).
-- bed_bath_table sells the most items but drops to 3rd in revenue,
-- because its products are cheaper (~93 per item).


-- 6. Which states have the customers who spend the most, in total and on average per customer?
SELECT customer_state,
       SUM(items_value)                                                AS rev_per_state,
       ROUND(SUM(items_value) / COUNT(DISTINCT customer_unique_id), 2) AS avg_rev_per_customer,
       COUNT(DISTINCT customer_unique_id)                              AS n_customers
FROM vw_orders
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY rev_per_state DESC
LIMIT 10;
-- Result: SP is first in total revenue (~5.07M, ~38% of the total) because it has
-- by far the most customers (39,156, ~42% of all customers). However, its average
-- spend per customer (129.42) is the lowest in the top 10.
-- BA is 7th in total revenue but has the highest average spend per customer
-- in the top 10 (156.30).


-- 7. How can customers be segmented by Recency, Frequency and Monetary value?
WITH rfm_base AS (
    -- One row per customer with the three RFM measures
    SELECT customer_unique_id,
           (SELECT MAX(order_purchase_timestamp)
            FROM vw_orders
            WHERE order_status = 'delivered')::date
           - MAX(order_purchase_timestamp)::date AS recency,      -- days since last purchase
           COUNT(order_id)                        AS frequency,    -- number of orders
           ROUND(SUM(items_value), 2)             AS monetary      -- total spend
    FROM vw_orders
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
),

rfm_scores AS (
    -- Scores: R and M from 1 to 5 (5 = best), F on two levels
    SELECT customer_unique_id,
           recency,
           frequency,
           monetary,
           NTILE(5) OVER (ORDER BY recency DESC)    AS r_score,
           CASE WHEN frequency = 1 THEN 1 ELSE 2 END AS f_score,
           NTILE(5) OVER (ORDER BY monetary)        AS m_score
    FROM rfm_base
),

rfm_segments AS (
    -- Segments (each customer gets the first matching rule)
    SELECT customer_unique_id,
           CASE
               WHEN r_score >= 4 AND m_score >= 4 THEN 'Champions'
               WHEN f_score = 2                   THEN 'Loyal'
               WHEN r_score <= 2 AND m_score >= 4 THEN 'At risk'
               WHEN r_score <= 2 AND m_score <= 2 THEN 'Lost'
               WHEN r_score >= 4                  THEN 'New'
               ELSE 'Others'
           END AS segment
    FROM rfm_scores
)

SELECT segment,
       COUNT(*) AS n_customers
FROM rfm_segments
GROUP BY segment
ORDER BY n_customers DESC;
-- Result (93,358 customers in total):
-- Others 25,381 | New 21,648 | Champions 15,424 | Lost 15,226 | At risk 13,810 | Loyal 1,869
-- - Only ~2% of customers are Loyal: almost all customers buy only once,
--   so customer retention is Olist's main weakness.
-- - 13,810 customers are At risk: they spent a lot but have not bought for a
--   long time. They are the most valuable group for a re-engagement campaign.
-- Note: since almost all customers have only one order, Frequency was reduced
-- to two levels (1 order / more than 1 order) instead of five.


-- 8. Which states have the highest percentage of late deliveries?
SELECT customer_state,
       ROUND(AVG(is_late) * 100, 2) AS pct_late_del,
       COUNT(order_id)              AS num_orders_per_state
FROM vw_orders
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY pct_late_del DESC;
-- Result: the states with the highest percentage of late deliveries are
-- AL (21.41%), MA (17.43%) and SE (15.22%), all with relatively few orders
-- (397, 717 and 335). They are all in the North-East of Brazil, far from SP,
-- where most sellers are located: distance could be a cause of the delays
-- (hypothesis). SP, with the most orders, has 4.49% of late deliveries.


-- 9. Do late deliveries receive worse review scores than on-time deliveries?
SELECT CASE
           WHEN is_late = 0 THEN 'On time'
           WHEN is_late = 1 THEN 'Late'
       END                          AS order_state,
       ROUND(AVG(avg_rev_score), 2) AS avg_rev_score,
       COUNT(order_id)              AS num_orders
FROM vw_orders
WHERE order_status = 'delivered'
  AND is_late IS NOT NULL
GROUP BY order_state;
-- Result: on-time orders have an average score of 4.29 (89,936 orders),
-- late orders of 2.27 (6,534 orders): about 2 points lower on a 1-5 scale.
-- Late orders are 6.8% of delivered orders (the 8 delivered orders without
-- a delivery date are excluded).
-- Delivery punctuality is strongly associated with customer satisfaction:
-- reducing delays, especially in the states with the highest late rates,
-- could significantly improve review scores.