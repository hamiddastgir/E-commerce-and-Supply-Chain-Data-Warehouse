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
