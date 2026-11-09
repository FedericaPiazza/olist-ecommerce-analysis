-- Creates the tables of the Olist database 

DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     customers, sellers, products, category_translation,
                     geolocation CASCADE;

CREATE TABLE orders (
    order_id                      varchar(32) NOT NULL,
    customer_id                   varchar(32) NOT NULL,
    order_status                  varchar(20) NOT NULL,
    order_purchase_timestamp      timestamp   NOT NULL,
    order_approved_at             timestamp   NULL,
    order_delivered_carrier_date  timestamp   NULL,
    order_delivered_customer_date timestamp   NULL,
    order_estimated_delivery_date timestamp   NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);

CREATE TABLE order_items (
    order_id            varchar(32)   NOT NULL,
    order_item_id       int           NOT NULL,
    product_id          varchar(32)   NOT NULL,
    seller_id           varchar(32)   NOT NULL,
    shipping_limit_date timestamp     NOT NULL,
    price               numeric(10,2) NOT NULL,
    freight_value       numeric(10,2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             varchar(32)   NOT NULL,
    payment_sequential   int           NOT NULL,
    payment_type         varchar(20)   NOT NULL,
    payment_installments int           NOT NULL,
    payment_value        numeric(10,2) NOT NULL,
    CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
    review_id               varchar(32) NOT NULL,
    order_id                varchar(32) NOT NULL,
    review_score            int         NOT NULL,
    review_comment_title    text        NULL,
    review_comment_message  text        NULL,
    review_creation_date    timestamp   NOT NULL,
    review_answer_timestamp timestamp   NOT NULL,
    CONSTRAINT pk_order_reviews PRIMARY KEY (review_id, order_id)
);

CREATE TABLE customers (
    customer_id              varchar(32)  NOT NULL,
    customer_unique_id       varchar(32)  NOT NULL,
    customer_zip_code_prefix varchar(5)   NOT NULL,
    customer_city            varchar(100) NOT NULL,
    customer_state           char(2)      NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);

CREATE TABLE sellers (
    seller_id              varchar(32)  NOT NULL,
    seller_zip_code_prefix varchar(5)   NOT NULL,
    seller_city            varchar(100) NOT NULL,
    seller_state           char(2)      NOT NULL,
    CONSTRAINT pk_sellers PRIMARY KEY (seller_id)
);

CREATE TABLE products (
    product_id                 varchar(32) NOT NULL,
    product_category_name      varchar(50) NULL,
    product_name_lenght        int         NULL,
    product_description_lenght int         NULL,
    product_photos_qty         int         NULL,
    product_weight_g           int         NULL,
    product_length_cm          int         NULL,
    product_height_cm          int         NULL,
    product_width_cm           int         NULL,
    CONSTRAINT pk_products PRIMARY KEY (product_id)
);

CREATE TABLE category_translation (
    product_category_name         varchar(50) NOT NULL,
    product_category_name_english varchar(50) NOT NULL,
    CONSTRAINT pk_category_translation PRIMARY KEY (product_category_name)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix varchar(5)   NOT NULL,
    geolocation_lat             numeric(9,6) NOT NULL,
    geolocation_lng             numeric(9,6) NOT NULL,
    geolocation_city            varchar(100) NOT NULL,
    geolocation_state           char(2)      NOT NULL
);