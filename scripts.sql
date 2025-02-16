-- Creating a staging schema

CREATE SCHEMA IF NOT EXISTS staging;

-- 

CREATE TABLE staging.orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);


CREATE TABLE staging.customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state CHAR(2)
);

CREATE TABLE staging.products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

CREATE TABLE staging.order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE staging.order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2)
);

CREATE TABLE staging.geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city TEXT,
    geolocation_state CHAR(2)
);

CREATE TABLE staging.sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state CHAR(2)
);

CREATE TABLE staging.order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC(10,2)
);

CREATE TABLE staging.product_category_name_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

-- Copying Files

COPY staging.orders
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/orders.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.customers
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/customers.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.order_items
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/order_items.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.order_payments
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/order_payments.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.reviews
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/reviews.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.products
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/products.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.product_category_name_translation
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/product_category_name_translation.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.sellers
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/sellers.csv'
WITH CSV HEADER DELIMITER ',';

COPY staging.geolocation
FROM '/Users/hamiddastgir/Hamid/PostgreSQL/SQL Project/Brazillian Dataset/geolocation.csv'
WITH CSV HEADER DELIMITER ',';

-- Checking row count

SELECT COUNT(*) FROM staging.orders;
SELECT COUNT(*) FROM staging.customers;
SELECT COUNT(*) FROM staging.order_items;
SELECT COUNT(*) FROM staging.order_payments;
SELECT COUNT(*) FROM staging.reviews;
SELECT COUNT(*) FROM staging.products;
SELECT COUNT(*) FROM staging.product_category_name_translation;
SELECT COUNT(*) FROM staging.sellers;
SELECT COUNT(*) FROM staging.geolocation;

