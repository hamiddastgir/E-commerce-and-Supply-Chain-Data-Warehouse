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


