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