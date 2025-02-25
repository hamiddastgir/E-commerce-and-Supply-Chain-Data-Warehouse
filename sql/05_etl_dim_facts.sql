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