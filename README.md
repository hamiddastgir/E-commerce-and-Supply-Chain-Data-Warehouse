# E-Commerce & Supply Chain Data Warehouse

**A comprehensive end-to-end data warehouse solution** integrating e-commerce transactions (orders, customers, products) with supply chain logistics (warehouse capacity, shipments) to enable advanced analytics and reporting.

---

## Overview

This repository showcases a **complete data warehousing pipeline** built from the ground up:
1. **Staging**: Ingests data from CSV/JSON sources (real and synthetic).
2. **Dimensional Modeling**: Implements a **star schema** with Slowly Changing Dimensions (SCD Type 2).
3. **Fact Tables**: Captures orders, order items, payments, reviews, and shipments.
4. **Performance Optimization**: Leverages window functions, partial indexes, and materialized views.
5. **Analytics**: Supports actionable insights like churn analysis, cross-sell opportunities, and shipping performance.

The **objective**: Deliver an **enterprise-grade platform** for e-commerce and supply chain analytics that scales efficiently, handles high data volumes, and supports extensibility.

---

## Key Features

- **Star Schema with SCD**  
  - Dimension tables (`dim_customer`, `dim_product`, `dim_seller`, `dim_date`, `dim_warehouse`) with surrogate keys.  
  - SCD Type 2 for `dim_customer` and `dim_warehouse` to track historical changes.
- **Staging & Validation**  
  - Dedicated `staging` schema with `CHECK` constraints and data cleansing (e.g., median imputation for weights, negative price detection).
- **Robust Fact Tables**  
  - `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`, `fact_shipments`—covering the full e-commerce lifecycle.
- **Performance Optimization**  
  - Window functions (e.g., rolling averages, rankings).  
  - Partitioning and materialized views for large datasets (optional).  
  - Indexes (e.g., foreign keys, partial indexes for "delivered" orders).
- **SCD Upserts**  
  - PL/pgSQL procedures to manage inserts and updates for dimension versioning.
- **Extensibility**  
  - Optional real-time streaming via triggers or incremental loads.

---

## Repository Structure
```
.
├── docs
│   ├── erd_diagram.png           # Entity-Relationship Diagram (Crow's Foot notation)
│   └── Scope_and_Objectives.md   # Project scope and business context
├── sql
│   ├── 01_create_staging_tables.sql   # Create staging tables
│   ├── 02_load_staging_data.sql       # Load data into staging
│   ├── 03_create_dim_tables.sql       # Create dimension tables
│   ├── 04_create_fact_tables.sql      # Create fact tables
│   ├── 05_etl_dim_facts.sql           # ETL for dimensions and facts
│   ├── 06_scd_upserts.sql             # SCD Type 2 upsert logic
│   ├── 07_add_constraints_indexes.sql # Add constraints and indexes
│   ├── all_scripts_combined.sql       # Combined script for all steps
│   └── ANALYTICS.sql                  # Advanced analytics queries
├── data_files
│   ├── orders.csv
│   ├── customers.csv
│   ├── synthetic_warehouses.csv
│   ├── order_items.csv
│   ├── order_payments.csv
│   ├── product_category_name_translation.csv
│   ├── products.csv
│   ├── reviews.csv
│   ├── sellers.csv
│   ├── synthetic_shipments.csv
│   └── geolocation.csv
├── synthetic_data_script.ipynb   # Jupyter notebook for synthetic data generation
├── README.md                     # This file
└── LICENSE                       # MIT License (optional)
```

> **Note**: SQL scripts are modular but can be combined or adapted as needed.

---

## Prerequisites & Setup

1. **PostgreSQL 16** (local or Docker)  
   - Compatible with older versions (e.g., 9.6/10) with minor adjustments.
2. **Python 3.9+** (optional, for synthetic data generation)  
   - Required libraries: `pandas`, `psycopg2`.
3. **Git** for version control.

### Install Dependencies (Python)

```bash
pip install psycopg2-binary pandas
```

### Create the Database

```bash
psql -U postgres -c "CREATE DATABASE ecommerce_warehouse;"
```

## How to Run

### Clone the Repository  

```bash
git clone https://github.com/YourName/ecommerce-warehouse.git
cd ecommerce-warehouse
```

### (Optional) Generate Synthetic Data  

Run `synthetic_data_script.ipynb` to create `synthetic_warehouses.csv` and `synthetic_shipments.csv`.  
Save outputs to `/data_files`.

### Create Staging Tables & Load Data  

```bash
psql -U postgres -d ecommerce_warehouse -f sql/01_create_staging_tables.sql
psql -U postgres -d ecommerce_warehouse -f sql/02_load_staging_data.sql
```

### Create Dimension & Fact Tables  

```bash
psql -U postgres -d ecommerce_warehouse -f sql/03_create_dim_tables.sql
psql -U postgres -d ecommerce_warehouse -f sql/04_create_fact_tables.sql
```

### Run ETL for Dimensions & Facts  

```bash
psql -U postgres -d ecommerce_warehouse -f sql/05_etl_dim_facts.sql
```

### Apply SCD Upserts  

```bash
psql -U postgres -d ecommerce_warehouse -f sql/06_scd_upserts.sql
```

### Add Constraints & Indexes  

```bash
psql -U postgres -d ecommerce_warehouse -f sql/07_add_constraints_indexes.sql
```

### Run Analytics Queries  

```bash
psql -U postgres -d ecommerce_warehouse -f sql/ANALYTICS.sql
```

> **Tip**: Use `all_scripts_combined.sql` to execute all steps in one go.

## Data Model

View the ERD in `/docs/erd_diagram.png`. Key elements:

- **Dimensions**: `dim_customer`, `dim_product`, `dim_seller`, `dim_date`, `dim_warehouse`.  
  - Surrogate keys (e.g., `customer_key`).  
  - SCD Type 2 attributes (`effective_start_date`, `effective_end_date`, `is_current`).
- **Facts**: `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`, `fact_shipments`.  
  - Foreign keys linking to dimensions.  
  - Metrics (e.g., `price`, `freight_value`, `shipping_cost`).

## Advanced Features

### SCD Type 2  
- Upsert procedures (`06_scd_upserts.sql`) for versioning `dim_customer` and `dim_warehouse`.

### Analytics  
- Window functions for rolling averages, rankings, and churn detection.  
- Basket analysis for product co-occurrences.

### Performance  
- Foreign key indexes and partial indexes (e.g., delivered orders).  
- Optional partitioning and materialized views for large datasets.

### Scalability  
- Incremental load support via triggers (see comments in scripts).

## Next Steps

### Real-Time Ingestion  
- Add triggers or cron jobs for near-real-time updates.

### Security  
- Implement roles (e.g., `analyst_role` for read-only access).

### Visualization  
- Connect to Power BI/Tableau and export dashboards to the repo.

## Contributing

- Fork the repo and submit pull requests for new features or queries.
- For significant changes, open an issue to discuss first.

## Contact & License

- Author: Hamid Dastgir  
- License: MIT (see LICENSE file).

Explore, adapt, and enhance this data warehouse for your own projects or portfolio. Happy analyzing!

> "Data is a precious thing and will last longer than the systems themselves." – Tim Berners-Lee