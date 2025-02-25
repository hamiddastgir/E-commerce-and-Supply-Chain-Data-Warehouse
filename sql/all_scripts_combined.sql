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

