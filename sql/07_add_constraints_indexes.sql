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

