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