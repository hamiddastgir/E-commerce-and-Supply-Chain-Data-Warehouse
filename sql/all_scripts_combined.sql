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

CREATE TABLE staging.reviews (
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

-- Verifying Row Count

SELECT COUNT(*) FROM staging.orders;
SELECT COUNT(*) FROM staging.customers;
SELECT COUNT(*) FROM staging.order_items;
SELECT COUNT(*) FROM staging.order_payments;
SELECT COUNT(*) FROM staging.reviews;
SELECT COUNT(*) FROM staging.products;
SELECT COUNT(*) FROM staging.product_category_name_translation;
SELECT COUNT(*) FROM staging.sellers;
SELECT COUNT(*) FROM staging.geolocation;

-- Done

-- Checking for null values

SELECT COUNT(*) AS total_rows,
       COUNT(order_id) AS non_null_orders,
       COUNT(customer_id) AS non_null_customers,
       COUNT(order_purchase_timestamp) AS non_null_purchase_dates
FROM staging.orders;


SELECT COUNT(*) AS total_rows,
       COUNT(customer_id) AS non_null_customers,
       COUNT(customer_unique_id) AS non_null_unique_customers
FROM staging.customers;

SELECT COUNT(*) AS total_rows,
       COUNT(product_id) AS non_null_products,
       COUNT(product_category_name) AS non_null_categories,
       COUNT(product_weight_g) AS non_null_weight
FROM staging.products;

SELECT product_id, COUNT(*)
FROM staging.products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Checking Valid Date ranges

SELECT MIN(order_purchase_timestamp) AS earliest_order, 
       MAX(order_purchase_timestamp) AS latest_order
FROM staging.orders;


SELECT MIN(review_creation_date) AS earliest_review, 
       MAX(review_creation_date) AS latest_review
FROM staging.reviews;

-- Detecting Duplicate Primary Keys

SELECT order_id, COUNT(*)
FROM staging.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*)
FROM staging.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Checking for Outliers

SELECT MIN(product_weight_g) AS min_weight,
       MAX(product_weight_g) AS max_weight
FROM staging.products;

SELECT MIN(freight_value) AS min_freight,
       MAX(freight_value) AS max_freight
FROM staging.olist_order_items;

-- Products table's category field had null values. Fixing the null values within Product table by setting values as unknown

UPDATE staging.products
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;

-- Checking median of product_weight_g and imputing it with the median weight

SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g) 
FROM staging.products
WHERE product_weight_g IS NOT NULL;

UPDATE staging.products
SET product_weight_g = (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g) 
                        FROM staging.products WHERE product_weight_g IS NOT NULL)
WHERE product_weight_g IS NULL;

-- Query to check if all NULL values have been handles

SELECT product_id, COUNT(*)
FROM staging.products
GROUP BY product_id
HAVING COUNT(*) > 1; -- no null values


-- Create dw Schema

CREATE SCHEMA IF NOT EXISTS dw;

-- Create Dimension Tables

-- dim_customer

CREATE TABLE dw.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id TEXT UNIQUE NOT NULL,
    customer_unique_id TEXT,
    customer_city TEXT,
    customer_state TEXT,
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    is_current BOOLEAN DEFAULT TRUE
);

-- dim_product

CREATE TABLE dw.dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id TEXT UNIQUE NOT NULL,
    product_category_name TEXT,
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- dim_seller

CREATE TABLE dw.dim_seller (
    seller_key SERIAL PRIMARY KEY,
    seller_id TEXT UNIQUE NOT NULL,
    seller_city TEXT,
    seller_state TEXT
);

-- dim_date

CREATE TABLE dw.dim_date (
    date_key SERIAL PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INT,
    quarter INT,
    month INT,
    day INT,
    day_of_week TEXT,
    is_weekend BOOLEAN
);

-- dim_geolocation

CREATE TABLE dw.dim_geolocation (
    geolocation_key SERIAL PRIMARY KEY,
    zip_code_prefix TEXT UNIQUE NOT NULL,
    latitude NUMERIC(10, 6),
    longitude NUMERIC(10, 6),
    city TEXT,
    state TEXT
);


-- dim_category

CREATE TABLE dw.dim_category (
    category_key SERIAL PRIMARY KEY,
    product_category_name TEXT UNIQUE NOT NULL,
    product_category_name_english TEXT
);

-- CREATE FACT Tables

-- fact_orders

CREATE TABLE dw.fact_orders (
    order_key SERIAL PRIMARY KEY,
    order_id TEXT UNIQUE NOT NULL,
    customer_key INT NOT NULL,
    order_status TEXT,
    order_purchase_date DATE,
    order_approved_date DATE,
    order_delivered_date DATE,
    order_estimated_delivery_date DATE,
    FOREIGN KEY (customer_key) REFERENCES dw.dim_customer(customer_key)
);

-- fact_order_items

CREATE TABLE dw.fact_order_items (
    order_item_key SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    product_key INT NOT NULL,
    seller_key INT NOT NULL,
    price NUMERIC(10, 2),
    freight_value NUMERIC(10, 2),
    FOREIGN KEY (product_key) REFERENCES dw.dim_product(product_key),
    FOREIGN KEY (seller_key) REFERENCES dw.dim_seller(seller_key)
);

-- fact_payments

CREATE TABLE dw.fact_payments (
    payment_key SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    payment_type TEXT,
    payment_installments INT,
    payment_value NUMERIC(10, 2)
);

-- fact_reviews

CREATE TABLE dw.fact_reviews (
    review_key SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    review_score INT,
    review_comment TEXT,
    review_creation_date DATE
);

-- 3: Move Data from Staging to DW

-- ETL for Dimension Tables

-- dim_customer

INSERT INTO dw.dim_customer (customer_id, customer_unique_id, customer_city, customer_state)
SELECT DISTINCT customer_id, customer_unique_id, customer_city, customer_state
FROM staging.customers;

-- dim_product

INSERT INTO dw.dim_product (product_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
SELECT DISTINCT product_id, COALESCE(product_category_name, 'unknown'), product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm
FROM staging.products;

-- dim_seller

INSERT INTO dw.dim_seller (seller_id, seller_city, seller_state)
SELECT DISTINCT seller_id, seller_city, seller_state
FROM staging.sellers;

-- dim_date (For Order Dates)

INSERT INTO dw.dim_date (full_date, year, quarter, month, day, day_of_week, is_weekend)
SELECT DISTINCT order_purchase_timestamp::DATE,
       EXTRACT(YEAR FROM order_purchase_timestamp),
       EXTRACT(QUARTER FROM order_purchase_timestamp),
       EXTRACT(MONTH FROM order_purchase_timestamp),
       EXTRACT(DAY FROM order_purchase_timestamp),
       TO_CHAR(order_purchase_timestamp, 'Day'),
       CASE WHEN EXTRACT(DOW FROM order_purchase_timestamp) IN (0, 6) THEN TRUE ELSE FALSE END
FROM staging.orders;

-- dim_geolocation (IT DID NOT RUN NEED TO CONFIRM IF I HAD ACCIDENTLY RUN IT BEFORE)

INSERT INTO dw.dim_geolocation (zip_code_prefix, latitude, longitude, city, state)
SELECT DISTINCT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
FROM staging.geolocation;

-- dim_category

INSERT INTO dw.dim_category (product_category_name, product_category_name_english)
SELECT DISTINCT product_category_name, product_category_name_english
FROM staging.product_category_name_translation;

-- ETL for Fact Tables

-- fact_orders

INSERT INTO dw.fact_orders (order_id, customer_key, order_status, order_purchase_date, order_approved_date, order_delivered_date, order_estimated_delivery_date)
SELECT o.order_id, c.customer_key, o.order_status, o.order_purchase_timestamp::DATE, o.order_approved_at::DATE, o.order_delivered_customer_date::DATE, o.order_estimated_delivery_date::DATE
FROM staging.orders AS o
JOIN dw.dim_customer c ON o.customer_id = c.customer_id;

-- fact_order_items

INSERT INTO dw.fact_order_items (order_id, product_key, seller_key, price, freight_value)
SELECT oi.order_id, p.product_key, s.seller_key, oi.price, oi.freight_value
FROM staging.order_items AS oi
JOIN dw.dim_product p ON oi.product_id = p.product_id
JOIN dw.dim_seller s ON oi.seller_id = s.seller_id;

-- fact_payments

INSERT INTO dw.fact_payments (order_id, payment_type, payment_installments, payment_value)
SELECT order_id, payment_type, payment_installments, payment_value
FROM staging.order_payments;


-- fact_reviews


INSERT INTO dw.fact_reviews (order_id, review_score, review_comment, review_creation_date)
SELECT order_id, review_score, review_comment_message, review_creation_date::DATE
FROM staging.reviews;

-- Verify Data 

SELECT COUNT(*) FROM dw.dim_customer;
SELECT COUNT(*) FROM dw.fact_orders;


-- Upon review, may need to delete tables

DROP TABLE IF EXISTS dw.fact_order_items CASCADE;
DROP TABLE IF EXISTS dw.fact_reviews CASCADE;
DROP TABLE IF EXISTS dw.fact_payments CASCADE;
DROP TABLE IF EXISTS dw.fact_orders CASCADE;

-- 1. Revised fact_orders with Date Dimension Keys
-- 1.1 Create the Table

CREATE TABLE dw.fact_orders (
    order_key SERIAL PRIMARY KEY,
    order_id TEXT UNIQUE NOT NULL,
    customer_key INT NOT NULL,
    order_status TEXT,

    -- Instead of storing raw dates, store foreign keys referencing dim_date
    order_purchase_date_key INT,
    order_approved_date_key INT,
    order_delivered_date_key INT,
    order_estimated_delivery_date_key INT,

    FOREIGN KEY (customer_key) REFERENCES dw.dim_customer(customer_key),
    FOREIGN KEY (order_purchase_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (order_approved_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (order_delivered_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (order_estimated_delivery_date_key) REFERENCES dw.dim_date(date_key)
);

--1.2 Insert Data

INSERT INTO dw.fact_orders (
    order_id,
    customer_key,
    order_status,
    order_purchase_date_key,
    order_approved_date_key,
    order_delivered_date_key,
    order_estimated_delivery_date_key
)
SELECT
    o.order_id,
    c.customer_key,
    o.order_status,
    -- LEFT JOIN to dim_date for each date column
    dd.date_key    AS purchase_date_key,
    da.date_key    AS approved_date_key,
    dd2.date_key   AS delivered_date_key,
    dd3.date_key   AS estimated_date_key
FROM staging.orders AS o
JOIN dw.dim_customer c 
    ON o.customer_id = c.customer_id
-- For each date, match to dim_date.full_date
LEFT JOIN dw.dim_date dd  
    ON dd.full_date = o.order_purchase_timestamp::DATE
LEFT JOIN dw.dim_date da  
    ON da.full_date = o.order_approved_at::DATE
LEFT JOIN dw.dim_date dd2 
    ON dd2.full_date = o.order_delivered_customer_date::DATE
LEFT JOIN dw.dim_date dd3 
    ON dd3.full_date = o.order_estimated_delivery_date::DATE;

--Note: Using LEFT JOIN ensures that if a date is missing (NULL), we won’t lose the entire row; it’ll just store NULL in the corresponding _date_key column.

-- 2. Revised fact_order_items Linking to fact_orders
-- 2.1 Drop/Alter & Create the Table

CREATE TABLE dw.fact_order_items (
    order_item_key SERIAL PRIMARY KEY,

    -- Surrogate reference to the parent order
    order_key INT NOT NULL,

    product_key INT NOT NULL,
    seller_key INT NOT NULL,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),

    FOREIGN KEY (order_key) REFERENCES dw.fact_orders(order_key),
    FOREIGN KEY (product_key) REFERENCES dw.dim_product(product_key),
    FOREIGN KEY (seller_key) REFERENCES dw.dim_seller(seller_key)
);

-- 2.2 Insert Data

INSERT INTO dw.fact_order_items (
    order_key,
    product_key,
    seller_key,
    price,
    freight_value
)
SELECT 
    fo.order_key,
    p.product_key,
    s.seller_key,
    oi.price,
    oi.freight_value
FROM staging.order_items AS oi
-- Link back to the dimension tables
JOIN dw.dim_product p 
    ON oi.product_id = p.product_id
JOIN dw.dim_seller s 
    ON oi.seller_id = s.seller_id
-- Convert order_id -> order_key via fact_orders
JOIN dw.fact_orders fo 
    ON oi.order_id = fo.order_id;

-- Note: If an order_id in staging.order_items has no matching order_id in fact_orders, that row will be excluded— typically meaning the order wasn’t found or inserted.

-- 3. Revised fact_payments Linking to fact_orders
-- 3.1 Create Table

CREATE TABLE dw.fact_payments (
    payment_key SERIAL PRIMARY KEY,
    order_key INT NOT NULL,
    payment_type TEXT,
    payment_installments INT,
    payment_value NUMERIC(10,2),
    FOREIGN KEY (order_key) REFERENCES dw.fact_orders(order_key)
);

-- 3.2 Insert Data

INSERT INTO dw.fact_payments (
    order_key,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    fo.order_key,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM staging.order_payments AS op
JOIN dw.fact_orders fo 
    ON op.order_id = fo.order_id;

-- 4. Revised fact_reviews Linking to fact_orders and dim_date
-- 4.1 Create Table

CREATE TABLE dw.fact_reviews (
    review_key SERIAL PRIMARY KEY,
    order_key INT NOT NULL,
    review_score INT,
    review_comment TEXT,
    -- Link to date dimension if you want
    review_creation_date_key INT,
    FOREIGN KEY (order_key) REFERENCES dw.fact_orders(order_key),
    FOREIGN KEY (review_creation_date_key) REFERENCES dw.dim_date(date_key)
);

-- 4.2 Insert Data

INSERT INTO dw.fact_reviews (
    order_key,
    review_score,
    review_comment,
    review_creation_date_key
)
SELECT 
    fo.order_key,
    r.review_score,
    r.review_comment_message,
    dd.date_key
FROM staging.reviews AS r
JOIN dw.fact_orders fo
    ON r.order_id = fo.order_id
LEFT JOIN dw.dim_date dd
    ON dd.full_date = r.review_creation_date::DATE;



-- After generating warehouse and shipment using Python
-- I tried db injection first, and that resulted in the tables being created so I now have to get rid of them

DROP TABLE IF EXISTS staging.synthetic_warehouse CASCADE;
DROP TABLE IF EXISTS staging.synthetic_shipments CASCADE;


-- Now, create them cleanly:
CREATE TABLE IF NOT EXISTS staging.synthetic_warehouse (
    synthetic_warehouse_id INT,
    warehouse_name TEXT,
    warehouse_location TEXT,
    capacity INT
);

CREATE TABLE IF NOT EXISTS staging.synthetic_shipments (
    synthetic_shipment_id INT,
    order_id TEXT,
    warehouse_id INT,
    carrier TEXT,
    ship_date TIMESTAMP,
    delivery_date TIMESTAMP,
    shipping_cost NUMERIC(10,2)
);

-- Loading the CSV files
COPY staging.synthetic_warehouse
  FROM '/Users/hamiddastgir/Hamid/PostgreSQL/E-commerce-and-Supply-Chain-Data-Warehouse/data_files/synthetic_warehouses.csv'
  CSV HEADER;

COPY staging.synthetic_shipments
  FROM '/Users/hamiddastgir/Hamid/PostgreSQL/E-commerce-and-Supply-Chain-Data-Warehouse/data_files/synthetic_shipments.csv'
  CSV HEADER;

  -- 5.1 Create dim_warehouse (if not exist)
CREATE TABLE IF NOT EXISTS dw.dim_warehouse (
    warehouse_key SERIAL PRIMARY KEY,
    synthetic_warehouse_id INT UNIQUE,
    warehouse_name TEXT,
    warehouse_location TEXT,
    capacity INT
);

-- 5.2 Insert from staging
INSERT INTO dw.dim_warehouse (
    synthetic_warehouse_id,
    warehouse_name,
    warehouse_location,
    capacity
)
SELECT 
    synthetic_warehouse_id,
    warehouse_name,
    warehouse_location,
    capacity
FROM staging.synthetic_warehouse;

-- 5.3 Create fact_shipments
CREATE TABLE IF NOT EXISTS dw.fact_shipments (
    shipment_key SERIAL PRIMARY KEY,
    order_key INT NOT NULL,
    warehouse_key INT NOT NULL,
    carrier TEXT,
    ship_date TIMESTAMP,
    delivery_date TIMESTAMP,
    shipping_cost NUMERIC(10,2),

    FOREIGN KEY (order_key) REFERENCES dw.fact_orders(order_key),
    FOREIGN KEY (warehouse_key) REFERENCES dw.dim_warehouse(warehouse_key)
);

-- 5.4 Insert into fact_shipments
INSERT INTO dw.fact_shipments (
    order_key,
    warehouse_key,
    carrier,
    ship_date,
    delivery_date,
    shipping_cost
)
SELECT
    fo.order_key,
    w.warehouse_key,
    s.carrier,
    s.ship_date,
    s.delivery_date,
    s.shipping_cost
FROM staging.synthetic_shipments s

JOIN dw.fact_orders fo
  ON s.order_id = fo.order_id

JOIN dw.dim_warehouse w
  ON s.warehouse_id = w.synthetic_warehouse_id;

-- Add SCD Columns to dim_warehouse
-- dim_warehouse

ALTER TABLE dw.dim_warehouse
    ADD COLUMN IF NOT EXISTS effective_start_date DATE DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS effective_end_date DATE,
    ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT TRUE;

-- Upsert Procedure for dim_customer

CREATE OR REPLACE PROCEDURE dw.upsert_dim_customer(
    p_customer_id TEXT,
    p_customer_unique_id TEXT,
    p_customer_city TEXT,
    p_customer_state TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_key INT;
    v_existing_city TEXT;
    v_existing_state TEXT;
BEGIN
    -- 1) Find if there's a current row for this customer_id
    SELECT customer_key, customer_city, customer_state
      INTO v_existing_key, v_existing_city, v_existing_state
      FROM dw.dim_customer
     WHERE customer_id = p_customer_id
       AND is_current = TRUE
     LIMIT 1;

    IF NOT FOUND THEN
        -- 2) No current row => Insert brand-new
        INSERT INTO dw.dim_customer(
            customer_id,
            customer_unique_id,
            customer_city,
            customer_state,
            effective_start_date,
            effective_end_date,
            is_current
        )
        VALUES (
            p_customer_id,
            p_customer_unique_id,
            p_customer_city,
            p_customer_state,
            CURRENT_DATE, -- start now
            NULL,
            TRUE
        );

    ELSE
        -- 3) Found existing row => compare city/state
        IF v_existing_city = p_customer_city
           AND v_existing_state = p_customer_state
        THEN
            -- 3a) No changes => do nothing
            RAISE NOTICE 'No changes for customer %', p_customer_id;
        ELSE
            -- 3b) Something changed => end-date old row, insert a new version
            UPDATE dw.dim_customer
               SET effective_end_date = CURRENT_DATE,
                   is_current = FALSE
             WHERE customer_key = v_existing_key;

            INSERT INTO dw.dim_customer(
                customer_id,
                customer_unique_id,
                customer_city,
                customer_state,
                effective_start_date,
                effective_end_date,
                is_current
            )
            VALUES (
                p_customer_id,
                p_customer_unique_id,
                p_customer_city,
                p_customer_state,
                CURRENT_DATE,
                NULL,
                TRUE
            );
        END IF;
    END IF;
END;
$$;


-- Upsert Procedure for dim_warehouse

CREATE OR REPLACE PROCEDURE dw.upsert_dim_warehouse(
    p_synthetic_warehouse_id INT,
    p_warehouse_name TEXT,
    p_warehouse_location TEXT,
    p_capacity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_key INT;
    v_existing_location TEXT;
    v_existing_capacity INT;
BEGIN
    -- 1) Find current row for this synthetic_warehouse_id
    SELECT warehouse_key, warehouse_location, capacity
      INTO v_existing_key, v_existing_location, v_existing_capacity
      FROM dw.dim_warehouse
     WHERE synthetic_warehouse_id = p_synthetic_warehouse_id
       AND is_current = TRUE
     LIMIT 1;

    IF NOT FOUND THEN
        -- 2) No current row => Insert brand-new
        INSERT INTO dw.dim_warehouse(
            synthetic_warehouse_id,
            warehouse_name,
            warehouse_location,
            capacity,
            effective_start_date,
            effective_end_date,
            is_current
        )
        VALUES (
            p_synthetic_warehouse_id,
            p_warehouse_name,
            p_warehouse_location,
            p_capacity,
            CURRENT_DATE,
            NULL,
            TRUE
        );

    ELSE
        -- 3) Existing row => compare location/capacity
        IF v_existing_location = p_warehouse_location
           AND v_existing_capacity = p_capacity
        THEN
            RAISE NOTICE 'No changes for warehouse_id %', p_synthetic_warehouse_id;
        ELSE
            UPDATE dw.dim_warehouse
               SET effective_end_date = CURRENT_DATE,
                   is_current = FALSE
             WHERE warehouse_key = v_existing_key;

            INSERT INTO dw.dim_warehouse(
                synthetic_warehouse_id,
                warehouse_name,
                warehouse_location,
                capacity,
                effective_start_date,
                effective_end_date,
                is_current
            )
            VALUES (
                p_synthetic_warehouse_id,
                p_warehouse_name,
                p_warehouse_location,
                p_capacity,
                CURRENT_DATE,
                NULL,
                TRUE
            );
        END IF;
    END IF;
END;
$$;

-- 5. Example Usage: Loading “Changed” Records (I AM NOT RUNNING THIS, THIS IS DEMO CODE JUST IN CASE)
-- 5.1 Suppose you have new or updated customers in staging.customers_delta

DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (
        SELECT customer_id, customer_unique_id, customer_city, customer_state
        FROM staging.customers_delta
    )
    LOOP
        CALL dw.upsert_dim_customer(
            rec.customer_id,
            rec.customer_unique_id,
            rec.customer_city,
            rec.customer_state
        );
    END LOOP;
END;
$$;

-- 5.2 Suppose new or updated warehouses in staging.warehouse_updates

DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (
        SELECT synthetic_warehouse_id, warehouse_name, warehouse_location, capacity
        FROM staging.warehouse_updates
    )
    LOOP
        CALL dw.upsert_dim_warehouse(
            rec.synthetic_warehouse_id,
            rec.warehouse_name,
            rec.warehouse_location,
            rec.capacity
        );
    END LOOP;
END;
$$;

-- Adding SCD columns on dim_product

ALTER TABLE dw.dim_product
  ADD COLUMN IF NOT EXISTS effective_start_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS effective_end_date DATE,
  ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT TRUE;

-- Create the Upsert Procedure

  CREATE OR REPLACE PROCEDURE dw.upsert_dim_product(
    p_product_id TEXT,
    p_category_name TEXT,
    p_weight_g INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_key INT;
    v_existing_category TEXT;
    v_existing_weight INT;
BEGIN
    -- 1) Find current row for this product_id
    SELECT product_key,
           product_category_name,
           product_weight_g
      INTO v_existing_key,
           v_existing_category,
           v_existing_weight
      FROM dw.dim_product
     WHERE product_id = p_product_id
       AND is_current = TRUE
     LIMIT 1;

    IF NOT FOUND THEN
        -- 2) No current row => Insert brand-new record
        INSERT INTO dw.dim_product(
            product_id,
            product_category_name,
            product_weight_g,
            effective_start_date,
            effective_end_date,
            is_current
        )
        VALUES (
            p_product_id,
            p_category_name,
            p_weight_g,
            CURRENT_DATE,
            NULL,
            TRUE
        );

    ELSE
        -- 3) We have an existing row => compare the attributes
        IF (v_existing_category = p_category_name)
           AND (v_existing_weight = p_weight_g)
        THEN
            -- 3a) No attribute changes => do nothing
            RAISE NOTICE 'No changes for product %', p_product_id;
        ELSE
            -- 3b) Something changed => end-date old record, insert new version
            UPDATE dw.dim_product
               SET effective_end_date = CURRENT_DATE,
                   is_current = FALSE
             WHERE product_key = v_existing_key;

            INSERT INTO dw.dim_product(
                product_id,
                product_category_name,
                product_weight_g,
                effective_start_date,
                effective_end_date,
                is_current
            )
            VALUES (
                p_product_id,
                p_category_name,
                p_weight_g,
                CURRENT_DATE,
                NULL,
                TRUE
            );
        END IF;
    END IF;
END;
$$;

-- 3. Using the Upsert Procedure
-- 3.1 Example: staging.product_updates table

CREATE TABLE IF NOT EXISTS staging.product_updates (
    product_id TEXT,
    product_category_name TEXT,
    product_weight_g INT
    -- plus other columns if you want
);

-- 3.2 Calling the Procedure for Each Updated Row

DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (
        SELECT product_id, product_category_name, product_weight_g
        FROM staging.product_updates
    )
    LOOP
        CALL dw.upsert_dim_product(
            rec.product_id,
            rec.product_category_name,
            rec.product_weight_g
        );
    END LOOP;
END;
$$;

-- 1. Create or Alter Tables to Add CHECK Constraints
-- Price / Freight / Payment Non-Negative


-- Ensuring none of these cost-related fields can be below zero.
-- In staging.order_items, ensure price and freight_value >= 0
ALTER TABLE staging.order_items
  ADD CONSTRAINT chk_order_items_price_nonnegative CHECK (price >= 0),
  ADD CONSTRAINT chk_order_items_freight_nonnegative CHECK (freight_value >= 0);

  -- In staging.order_payments, ensure payment_value >= 0
ALTER TABLE staging.order_payments
  ADD CONSTRAINT chk_order_payments_value_nonnegative
    CHECK (payment_value >= 0);

-- In staging.synthetic_shipments, ensure shipping_cost >= 0
ALTER TABLE staging.synthetic_shipments
  ADD CONSTRAINT chk_shipments_shipping_cost_nonnegative
    CHECK (shipping_cost >= 0);

-- Warehouse Capacity Non-Negative
-- Ensuring your synthetic data or future updates don’t set capacity to a negative number
ALTER TABLE dw.dim_warehouse
  ADD CONSTRAINT chk_warehouse_capacity_nonnegative
    CHECK (capacity >= 0);



-- Creating Indexes on Foreign Key Columns

-- 2.1 fact_orders Indexes

CREATE INDEX idx_fact_orders_customer_key 
  ON dw.fact_orders (customer_key);

-- Date dimension keys
CREATE INDEX idx_fact_orders_purchase_date_key 
  ON dw.fact_orders (order_purchase_date_key);

CREATE INDEX idx_fact_orders_approved_date_key 
  ON dw.fact_orders (order_approved_date_key);

CREATE INDEX idx_fact_orders_delivered_date_key 
  ON dw.fact_orders (order_delivered_date_key);

CREATE INDEX idx_fact_orders_estimated_date_key 
  ON dw.fact_orders (order_estimated_delivery_date_key);


-- 2.2 fact_order_items
CREATE INDEX idx_fact_order_items_order_key 
  ON dw.fact_order_items (order_key);


CREATE INDEX idx_fact_order_items_product_key 
  ON dw.fact_order_items (product_key);

CREATE INDEX idx_fact_order_items_seller_key 
  ON dw.fact_order_items (seller_key);

-- 2.3 fact_payments

CREATE INDEX idx_fact_payments_order_key
  ON dw.fact_payments (order_key);

-- 2.4 fact_reviews

CREATE INDEX idx_fact_reviews_order_key
  ON dw.fact_reviews (order_key);

-- If you do date dimension referencing for review_creation_date_key (Ran this query)
CREATE INDEX idx_fact_reviews_review_date_key
  ON dw.fact_reviews (review_creation_date_key);

-- 2.5 fact_shipments

CREATE INDEX idx_fact_shipments_order_key 
  ON dw.fact_shipments (order_key);

CREATE INDEX idx_fact_shipments_warehouse_key
  ON dw.fact_shipments (warehouse_key);

-- 3. (Optional) Additional Targeted Indexes
-- 3.1 Searching by Non-Foreign Key Columns

CREATE INDEX idx_fact_orders_status 
  ON dw.fact_orders (order_status);

-- 3.2 Partial Indexes

-- order_purchaase_date_key
CREATE INDEX idx_fact_orders_delivered_only
ON dw.fact_orders (order_purchase_date_key)
WHERE order_status = 'delivered';

-- If you do SCD on dim_customer with is_current = TRUE:
CREATE INDEX idx_dim_customer_current
  ON dw.dim_customer (customer_id)
  WHERE is_current = TRUE;

-- If you do SCD on dim_warehouse with is_current = TRUE:
CREATE INDEX idx_dim_warehouse_current
  ON dw.dim_warehouse (synthetic_warehouse_id)
  WHERE is_current = TRUE;

-- ANALYTICS

-- Customer Churn Analysis
-- Identify customers who haven't placed an order in the last 90 days as of Feb 25, 2025
WITH last_order AS (
    SELECT 
        dc.customer_unique_id,
        dc.customer_city,
        dc.customer_state,
        MAX(dd.full_date) AS last_order_date,
        COUNT(DISTINCT fo.order_key) AS total_orders
    FROM dw.dim_customer dc
    JOIN dw.fact_orders fo ON dc.customer_key = fo.customer_key
    JOIN dw.dim_date dd ON fo.order_purchase_date_key = dd.date_key
    WHERE dc.is_current = TRUE
      AND fo.order_status = 'delivered'
    GROUP BY dc.customer_unique_id, dc.customer_city, dc.customer_state
),
churn_metrics AS (
    SELECT 
        customer_unique_id,
        customer_city,
        customer_state,
        last_order_date,
        total_orders,
        CURRENT_DATE - last_order_date AS days_since_last_order,
        CASE 
            WHEN CURRENT_DATE - last_order_date > 90 THEN 'Churned'
            ELSE 'Active'
        END AS churn_status
    FROM last_order
)
SELECT 
    churn_status,
    customer_state,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer,
    ROUND(AVG(days_since_last_order), 2) AS avg_days_since_last_order
FROM churn_metrics
GROUP BY churn_status, customer_state
ORDER BY churn_status, customer_count DESC;

-- RANKING WAREHOUSES BY AVERAGE SHIPPING COST

WITH warehouse_costs AS (
  SELECT
    fs.warehouse_key,
    ROUND(AVG(fs.shipping_cost), 2) AS avg_shipping_cost,
    COUNT(*) AS shipments_count
  FROM dw.fact_shipments fs
  GROUP BY fs.warehouse_key
)

SELECT
  w.warehouse_name,
  w.warehouse_location,
  wc.avg_shipping_cost,
  wc.shipments_count,
  RANK() OVER (ORDER BY wc.avg_shipping_cost ASC) AS cost_rank
FROM warehouse_costs wc
JOIN dw.dim_warehouse w
  ON wc.warehouse_key = w.warehouse_key
ORDER BY wc.avg_shipping_cost ASC;

-- Analyze warehouse shipping cost efficiency
WITH warehouse_metrics AS (
    SELECT 
        dw.warehouse_name,
        COUNT(DISTINCT fs.order_key) AS total_orders,
        SUM(fs.shipping_cost) AS total_shipping_cost,
        ROUND(SUM(fs.shipping_cost) / COUNT(DISTINCT fs.order_key), 2) AS cost_per_order,
        ROUND(AVG(CASE 
            WHEN fs.delivery_date <= dd_est.full_date THEN 1 
            ELSE 0 
        END) * 100, 2) AS on_time_delivery_pct
    FROM dw.fact_shipments fs
    JOIN dw.dim_warehouse dw ON fs.warehouse_key = dw.warehouse_key
    JOIN dw.fact_orders fo ON fs.order_key = fo.order_key
    JOIN dw.dim_date dd_est ON fo.order_estimated_delivery_date_key = dd_est.date_key
    WHERE fo.order_status = 'delivered'
      AND dw.is_current = TRUE
    GROUP BY dw.warehouse_name
)
SELECT 
    warehouse_name,
    total_orders,
    total_shipping_cost,
    cost_per_order,
    on_time_delivery_pct,
    RANK() OVER (ORDER BY cost_per_order ASC, on_time_delivery_pct DESC) AS efficiency_rank
FROM warehouse_metrics
ORDER BY efficiency_rank;

-- Identify Top 10% of Customers by Spend (CTE + Window)

WITH customer_spend AS (
  SELECT
    fo.customer_key,
    SUM(oi.price + oi.freight_value) AS total_spend
  FROM dw.fact_orders fo
  JOIN dw.fact_order_items oi ON fo.order_key = oi.order_key
  GROUP BY fo.customer_key
),

customer_ranks AS (
  SELECT
    cs.customer_key,
    cs.total_spend,
    NTILE(10) OVER (ORDER BY cs.total_spend DESC) AS spend_decile
  FROM customer_spend cs
)

SELECT
  dc.customer_id,
  dc.customer_city,
  cr.total_spend
FROM customer_ranks cr
JOIN dw.dim_customer dc
  ON cr.customer_key = dc.customer_key
WHERE cr.spend_decile = 1  -- top decile
ORDER BY cr.total_spend DESC;

-- Rolling 7-Day Average Sales per Product

WITH daily_sales AS (
    SELECT 
        dd.full_date,
        dp.product_id,
        dc.product_category_name_english,  -- Use English translation
        SUM(foi.price) AS daily_revenue,
        COUNT(DISTINCT foi.order_key) AS daily_orders
    FROM dw.fact_order_items foi
    JOIN dw.dim_product dp ON foi.product_key = dp.product_key
    JOIN dw.dim_category dc ON dp.product_category_name = dc.product_category_name  -- Join with translation table
    JOIN dw.fact_orders fo ON foi.order_key = fo.order_key
    JOIN dw.dim_date dd ON fo.order_purchase_date_key = dd.date_key
    WHERE fo.order_status = 'delivered'
    GROUP BY dd.full_date, dp.product_id, dc.product_category_name_english
)
SELECT 
    full_date,
    product_id,
    product_category_name_english AS product_category_name,  -- Rename for consistency
    daily_revenue,
    ROUND(AVG(daily_revenue) OVER (
        PARTITION BY product_id 
        ORDER BY full_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7day_avg_revenue,
    daily_orders
FROM daily_sales
ORDER BY product_id, full_date;

-- Top 10% of Customers by Lifetime Value (Using CTE)

WITH customer_ltv AS (
    SELECT 
        dc.customer_key,
        dc.customer_unique_id,
        dc.customer_city,
        dc.customer_state,
        SUM(foi.price + foi.freight_value) AS lifetime_value,
        COUNT(DISTINCT fo.order_key) AS order_count
    FROM dw.dim_customer dc
    JOIN dw.fact_orders fo ON dc.customer_key = fo.customer_key
    JOIN dw.fact_order_items foi ON fo.order_key = foi.order_key
    WHERE fo.order_status = 'delivered'
      AND dc.is_current = TRUE
    GROUP BY dc.customer_key, dc.customer_unique_id, dc.customer_city, dc.customer_state
),
ranked_customers AS (
    SELECT 
        customer_unique_id,
        customer_city,
        customer_state,
        lifetime_value,
        order_count,
        NTILE(10) OVER (ORDER BY lifetime_value DESC) AS value_decile
    FROM customer_ltv
)
SELECT 
    customer_unique_id,
    customer_city,
    customer_state,
    lifetime_value,
    order_count
FROM ranked_customers
WHERE value_decile = 1  -- Top 10%
ORDER BY lifetime_value DESC;

-- Average Shipping Time per Product (Correlated Subquery)

SELECT 
    dp.product_id,
    dc.product_category_name_english AS product_category_name,  -- Use English translation
    (
        SELECT AVG(fs.delivery_date - fs.ship_date)
        FROM dw.fact_shipments fs
        JOIN dw.fact_orders fo ON fs.order_key = fo.order_key
        JOIN dw.fact_order_items foi ON fo.order_key = foi.order_key
        WHERE foi.product_key = dp.product_key
          AND fs.delivery_date IS NOT NULL
          AND fs.ship_date IS NOT NULL
    ) AS avg_shipping_time
FROM dw.dim_product dp
JOIN dw.dim_category dc ON dp.product_category_name = dc.product_category_name  -- Join with translation table
WHERE EXISTS (
    SELECT 1
    FROM dw.fact_order_items foi
    JOIN dw.fact_orders fo ON foi.order_key = fo.order_key
    JOIN dw.fact_shipments fs ON fo.order_key = fs.order_key
    WHERE foi.product_key = dp.product_key
)
ORDER BY avg_shipping_time DESC NULLS LAST;

-- Orders Above Category Average Order Value (Subquery)

WITH category_avg AS (
    SELECT 
        dc.product_category_name_english,  -- Use English translation
        AVG(foi.price) AS avg_category_order_value
    FROM dw.fact_order_items foi
    JOIN dw.dim_product dp ON foi.product_key = dp.product_key
    JOIN dw.dim_category dc ON dp.product_category_name = dc.product_category_name  -- Join with translation table
    JOIN dw.fact_orders fo ON foi.order_key = fo.order_key
    WHERE fo.order_status = 'delivered'
    GROUP BY dc.product_category_name_english
)
SELECT 
    fo.order_id,
    dc.product_category_name_english AS product_category_name,  -- Use English translation
    SUM(foi.price) AS order_value,
    ROUND(ca.avg_category_order_value,2) as avg_category_order_value
FROM dw.fact_orders fo
JOIN dw.fact_order_items foi ON fo.order_key = foi.order_key
JOIN dw.dim_product dp ON foi.product_key = dp.product_key
JOIN dw.dim_category dc ON dp.product_category_name = dc.product_category_name  -- Join with translation table
JOIN category_avg ca ON dc.product_category_name_english = ca.product_category_name_english
WHERE fo.order_status = 'delivered'
GROUP BY fo.order_id, dc.product_category_name_english, ca.avg_category_order_value
HAVING SUM(foi.price) > ca.avg_category_order_value
ORDER BY order_value DESC;

-- Basket Analysis: Top Co-Occurring Products - Need name for this

WITH product_pairs AS (
    SELECT 
        p1.product_id AS product_a,
        p2.product_id AS product_b,
        COUNT(DISTINCT fo.order_key) AS co_occurrence_count
    FROM dw.fact_order_items foi1
    JOIN dw.fact_orders fo ON foi1.order_key = fo.order_key
    JOIN dw.fact_order_items foi2 ON fo.order_key = foi2.order_key
    JOIN dw.dim_product p1 ON foi1.product_key = p1.product_key
    JOIN dw.dim_product p2 ON foi2.product_key = p2.product_key
    WHERE p1.product_id < p2.product_id  -- Avoid duplicates (A-B vs B-A)
      AND fo.order_status = 'delivered'
    GROUP BY p1.product_id, p2.product_id
    HAVING COUNT(DISTINCT fo.order_key) > 5  -- Minimum threshold
)
SELECT 
    product_a,
    product_b,
    co_occurrence_count,
    RANK() OVER (PARTITION BY product_a ORDER BY co_occurrence_count DESC) AS rank
FROM product_pairs
ORDER BY product_a, rank;

-- Materialized View


CREATE MATERIALIZED VIEW dw.mv_monthly_sales_by_region AS
SELECT 
    dd.year,
    dd.month,
    dc.customer_state,
    SUM(foi.price) AS total_sales,
    COUNT(DISTINCT fo.order_key) AS order_count
FROM dw.fact_orders fo
JOIN dw.dim_date dd ON fo.order_purchase_date_key = dd.date_key
JOIN dw.dim_customer dc ON fo.customer_key = dc.customer_key
JOIN dw.fact_order_items foi ON fo.order_key = foi.order_key
WHERE fo.order_status = 'delivered'
GROUP BY dd.year, dd.month, dc.customer_state;

-- Refresh periodically
REFRESH MATERIALIZED VIEW dw.mv_monthly_sales_by_region;


-- The below codes did not work as intended (keeping for documentation)
ALTER TABLE dw.dim_product
  ADD COLUMN IF NOT EXISTS category_key INT,
  ADD CONSTRAINT fk_dim_product_category_key
    FOREIGN KEY (category_key)
    REFERENCES dw.dim_category(category_key);
-- Matching dim_product.product_category_name to dim_category.product_category_name
UPDATE dw.dim_product dp
SET category_key = dc.category_key
FROM dw.dim_category dc
WHERE dp.product_category_name = dc.product_category_name;
-- Dropping product_category_name Column
ALTER TABLE dw.dim_product
  DROP COLUMN product_category_name;
-- Linking dim_seller (or dim_warehouse) to dim_geolocation




-- CORRECTING ERRORS
--1. Ensure dim_product Is Ready
-- Drop any old constraints or columns that might conflict:
ALTER TABLE dw.dim_product
  DROP CONSTRAINT IF EXISTS fk_dim_product_category_key;

ALTER TABLE dw.dim_product
  DROP COLUMN IF EXISTS category_key,
  DROP COLUMN IF EXISTS category_name_english;

-- 2.1 Add category_key (FK) and category_name_english
ALTER TABLE dw.dim_product
  ADD COLUMN category_key INT,
  ADD COLUMN category_name_english TEXT;

  -- 2.2 Add foreign key referencing dim_category
ALTER TABLE dw.dim_product
  ADD CONSTRAINT fk_dim_product_category_key
    FOREIGN KEY (category_key)
    REFERENCES dw.dim_category(category_key);

-- 3. Migrate Data from dim_product.product_category_name to category_key & category_name_english

UPDATE dw.dim_product AS dp
SET 
    category_key = dc.category_key,
    category_name_english = dc.product_category_name_english
FROM dw.dim_category AS dc
WHERE dp.product_category_name = dc.product_category_name;

-- 4. (Optional) Drop product_category_name
ALTER TABLE dw.dim_product
  DROP COLUMN product_category_name;

  -- Didn't work


  -- Dropping it all

  DROP TABLE IF EXISTS dw.dim_product CASCADE;


  -- Recreating again
  CREATE TABLE dw.dim_product (
  product_key SERIAL PRIMARY KEY,
  product_id TEXT UNIQUE NOT NULL,
  product_category_name TEXT,
  product_name_length INT,
  product_description_length INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT,
  effective_start_date DATE DEFAULT CURRENT_DATE,
  effective_end_date DATE,
  is_current BOOLEAN DEFAULT TRUE
);

--  Reloading data from staging.products
INSERT INTO dw.dim_product (
  product_id,
  product_category_name,
  product_name_length,
  product_description_length,
  product_photos_qty,
  product_weight_g,
  product_length_cm,
  product_height_cm,
  product_width_cm,
  effective_start_date,
  is_current
)
SELECT DISTINCT 
  product_id,
  COALESCE(product_category_name, 'unknown'),
  product_name_length,
  product_description_length,
  product_photos_qty,
  product_weight_g,
  product_length_cm,
  product_height_cm,
  product_width_cm,
  CURRENT_DATE,
  TRUE
FROM staging.products;


-- Step 1: Add category_key
ALTER TABLE dw.dim_product
  ADD COLUMN IF NOT EXISTS category_key INT;

-- Add foreign key constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_constraint 
    WHERE conname = 'fk_dim_product_category_key'
  ) THEN
    ALTER TABLE dw.dim_product
      ADD CONSTRAINT fk_dim_product_category_key
        FOREIGN KEY (category_key)
        REFERENCES dw.dim_category(category_key);
  END IF;
END;
$$;

-- Step 2: Migrate data from product_category_name to category_key
UPDATE dw.dim_product dp
SET category_key = dc.category_key
FROM dw.dim_category dc
WHERE dp.product_category_name = dc.product_category_name;

-- Handle any unmatched rows (set to 'unknown' category)
INSERT INTO dw.dim_category (product_category_name, product_category_name_english)
SELECT 'unknown', 'unknown'
WHERE NOT EXISTS (
  SELECT 1 FROM dw.dim_category WHERE product_category_name = 'unknown'
)
ON CONFLICT (product_category_name) DO NOTHING;

UPDATE dw.dim_product dp
SET category_key = (SELECT category_key FROM dw.dim_category WHERE product_category_name = 'unknown')
WHERE category_key IS NULL;

-- Step 3: Verify the migration
SELECT 
  COUNT(*) AS total_rows,
  COUNT(category_key) AS non_null_category_key,
  COUNT(product_category_name) AS non_null_category_name
FROM dw.dim_product;

SELECT 
  dp.product_id,
  dp.product_category_name,
  dp.category_key,
  dc.product_category_name_english
FROM dw.dim_product dp
LEFT JOIN dw.dim_category dc ON dp.category_key = dc.category_key
LIMIT 10;

-- Step 4: (Optional) Drop product_category_name
ALTER TABLE dw.dim_product
  DROP COLUMN IF EXISTS product_category_name;


-- Geolocation is empty somehow, troubleshooting and rebuilding

INSERT INTO dw.dim_geolocation (
  zip_code_prefix,
  latitude,
  longitude,
  city,
  state
)
SELECT DISTINCT 
  geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state
FROM staging.geolocation
ON CONFLICT (zip_code_prefix) DO NOTHING;


-- Backup current dim_seller
CREATE TABLE dw.dim_seller_backup_20250305 AS 
SELECT * FROM dw.dim_seller;

-- Drop and recreate dim_seller with zip code
DROP TABLE dw.dim_seller CASCADE;

CREATE TABLE dw.dim_seller (
    seller_key SERIAL PRIMARY KEY,
    seller_id TEXT UNIQUE NOT NULL,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT,
    geolocation_key INT,
    CONSTRAINT fk_dim_seller_geolocation
      FOREIGN KEY (geolocation_key)
      REFERENCES dw.dim_geolocation(geolocation_key)
);

-- Repopulate from staging.sellers
INSERT INTO dw.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT DISTINCT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers;


-- populate geolocation_key
UPDATE dw.dim_seller ds
SET geolocation_key = dg.geolocation_key
FROM dw.dim_geolocation dg
WHERE ds.seller_zip_code_prefix = dg.zip_code_prefix;

-- Handle unmatched rows
INSERT INTO dw.dim_geolocation (zip_code_prefix, latitude, longitude, city, state)
SELECT 'unknown', 0.0, 0.0, 'unknown', 'unknown'
WHERE NOT EXISTS (
  SELECT 1 FROM dw.dim_geolocation WHERE zip_code_prefix = 'unknown'
)
ON CONFLICT (zip_code_prefix) DO NOTHING;

UPDATE dw.dim_seller ds
SET geolocation_key = (SELECT geolocation_key FROM dw.dim_geolocation WHERE zip_code_prefix = 'unknown')
WHERE geolocation_key IS NULL;

-- Verify

SELECT 
  COUNT(*) AS total_sellers,
  COUNT(geolocation_key) AS non_null_geo_key
FROM dw.dim_seller;

SELECT 
  seller_id,
  seller_zip_code_prefix,
  geolocation_key,
  seller_city,
  seller_state
FROM dw.dim_seller
LIMIT 5;

-- Exporting All Tables from PostgreSQL for POWER BI visualization

COPY staging.orders TO '/Users/hamiddastgir/Hamid/PostgreSQL/E-commerce-and-Supply-Chain-Data-Warehouse/csv_exports/staging_orders.csv' WITH CSV HEADER;


COPY staging.customers TO '/Users/hamiddastgir/Desktop/csv_export/staging_customers.csv' WITH CSV HEADER;
COPY staging.order_items TO '/Users/hamiddastgir/Desktop/csv_export/staging_order_items.csv' WITH CSV HEADER;
COPY staging.order_payments TO '/Users/hamiddastgir/Desktop/csv_export/staging_order_payments.csv' WITH CSV HEADER;
COPY staging.reviews TO '/Users/hamiddastgir/Desktop/csv_export/staging_reviews.csv' WITH CSV HEADER;
COPY staging.products TO '/Users/hamiddastgir/Desktop/csv_export/staging_products.csv' WITH CSV HEADER;
COPY staging.product_category_name_translation TO '/Users/hamiddastgir/Desktop/csv_export/staging_product_category_name_translation.csv' WITH CSV HEADER;
COPY staging.sellers TO '/Users/hamiddastgir/Desktop/csv_export/staging_sellers.csv' WITH CSV HEADER;
COPY staging.geolocation TO '/Users/hamiddastgir/Desktop/csv_export/staging_geolocation.csv' WITH CSV HEADER;
COPY staging.synthetic_warehouse TO '/Users/hamiddastgir/Desktop/csv_export/staging_synthetic_warehouse.csv' WITH CSV HEADER;
COPY staging.synthetic_shipments TO '/Users/hamiddastgir/Desktop/csv_export/staging_synthetic_shipments.csv' WITH CSV HEADER;

COPY dw.dim_customer TO '/Users/hamiddastgir/Desktop/csv_export/dim_customer.csv' WITH CSV HEADER;
COPY dw.dim_product TO '/Users/hamiddastgir/Desktop/csv_export/dim_product.csv' WITH CSV HEADER;
COPY dw.dim_seller TO '/Users/hamiddastgir/Desktop/csv_export/dim_seller.csv' WITH CSV HEADER;
COPY dw.dim_date TO '/Users/hamiddastgir/Desktop/csv_export/dim_date.csv' WITH CSV HEADER;
COPY dw.dim_geolocation TO '/Users/hamiddastgir/Desktop/csv_export/dim_geolocation.csv' WITH CSV HEADER;
COPY dw.dim_category TO '/Users/hamiddastgir/Desktop/csv_export/dim_category.csv' WITH CSV HEADER;
COPY dw.dim_warehouse TO '/Users/hamiddastgir/Desktop/csv_export/dim_warehouse.csv' WITH CSV HEADER;
COPY dw.fact_orders TO '/Users/hamiddastgir/Desktop/csv_export/fact_orders.csv' WITH CSV HEADER;
COPY dw.fact_order_items TO '/Users/hamiddastgir/Desktop/csv_export/fact_order_items.csv' WITH CSV HEADER;
COPY dw.fact_payments TO '/Users/hamiddastgir/Desktop/csv_export/fact_payments.csv' WITH CSV HEADER;
COPY dw.fact_reviews TO '/Users/hamiddastgir/Desktop/csv_export/fact_reviews.csv' WITH CSV HEADER;
COPY dw.fact_shipments TO '/Users/hamiddastgir/Desktop/csv_export/fact_shipments.csv' WITH CSV HEADER;

