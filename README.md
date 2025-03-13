# E-Commerce & Supply Chain Data Warehouse

A comprehensive end-to-end data warehouse and analytics solution that integrates e-commerce transactions (orders, customers, products) with supply chain logistics (warehouse capacity, shipments), culminating in a Power BI dashboard for actionable insights.

## Table of Contents
- [Project Overview](#project-overview)
- [Features & Architecture](#features--architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites & Setup](#prerequisites--setup)
- [How to Run](#how-to-run)
- [Data Model & ERD](#data-model--erd)
- [Advanced Features](#advanced-features)
- [Power BI Dashboard](#power-bi-dashboard)
- [Business Value](#business-value)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [Contact](#contact)

## Project Overview
This repository demonstrates a complete data warehousing pipeline built from scratch, covering:

- **Staging**: Ingests data from CSVs (both real and synthetic).
- **Dimensional Modeling**: Implements a star schema with Slowly Changing Dimensions (SCD Type 2).
- **Fact Tables**: Captures orders, order items, payments, reviews, and synthetic shipments.
- **Performance Optimization**: Uses window functions, partial indexes, and materialized views (optional).
- **Analytics & Visualization**: A robust Power BI dashboard provides insights into product sales, geospatial distribution, shipping performance, and payment trends.

## Features & Architecture

### Star Schema with SCD
- Dimension tables (dim_customer, dim_product, dim_seller, dim_date, dim_warehouse) with surrogate keys.
- SCD Type 2 for dim_customer and dim_warehouse to track historical changes.

### Staging & Validation
- Dedicated staging_ tables with CHECK constraints and data cleansing (e.g., median imputation for missing weights).

### Fact Tables
- fact_orders, fact_order_items, fact_payments, fact_reviews, fact_shipments—covering the entire e-commerce lifecycle, including synthetic shipments.

### Performance & Optimization
- Window functions for rolling averages and churn detection.
- Indexes and constraints for queries on large data sets.
- Partial indexes (e.g., for "delivered" orders).

### SCD Upserts
- 06_scd_upserts.sql manages Type 2 dimension versioning via PL/pgSQL stored procedures.

### Extensibility
- Easy to add new data sources or real-time streaming (via triggers or incremental load scripts).

## Repository Structure
A high-level view:

```
.
├── synthetic_data_script.ipynb   
├── csv_exports/                  # Exported CSVs for staging/Power BI
├── docs/
│   ├── erd_diagram.jpeg
│   └── Scope_and_Objectives.md
├── sql/
│   ├── 01_create_staging_tables.sql
│   ├── 02_load_staging_data.sql
│   ├── 03_create_dim_tables.sql
│   ├── 04_create_fact_tables.sql
│   ├── 05_etl_dim_facts.sql
│   ├── 06_scd_upserts.sql
│   ├── 07_add_constraints_indexes.sql
│   ├── all_scripts_combined.sql
│   └── ANALYTICS.sql
├── visualizations/
│   ├── ecommerce.pbix
│   ├── Dashboard.png
│   ├── Product_Sales.png
│   ├── Sales_Map.png
│   ├── Shipping_Analysis.png
│   └── Payment_Trends.png
└── README.md  
```

*Note: Adjust file paths or names as preferred.*

## Prerequisites & Setup

- **PostgreSQL 16** (or compatible)
  - Works on 9.6+ with minor modifications.
- **Python 3.9+** (optional)
  - Used for synthetic data generation in synthetic_data_script.ipynb.
  - Required libraries: pandas, psycopg2 (if you load data directly from Python).
- **Power BI Desktop** (for dashboard creation)
  - Alternatively, you can use Tableau or other BI tools.

### Python Dependencies
```bash
pip install psycopg2-binary pandas
```

### Database Creation
```bash
psql -U postgres -c "CREATE DATABASE ecommerce_warehouse;"
```

## How to Run

### 1. Clone the Repository
```bash
git clone https://github.com/YourName/ecommerce-warehouse.git
cd ecommerce-warehouse
```

### 2. (Optional) Generate Synthetic Data
Run synthetic_data_script.ipynb (Jupyter) to create:
- staging_synthetic_warehouse.csv
- staging_synthetic_shipments.csv

### 3. Create Staging Tables & Load Data
```bash
psql -U postgres -d ecommerce_warehouse -f sql/01_create_staging_tables.sql
psql -U postgres -d ecommerce_warehouse -f sql/02_load_staging_data.sql
```

### 4. Create Dimension & Fact Tables
```bash
psql -U postgres -d ecommerce_warehouse -f sql/03_create_dim_tables.sql
psql -U postgres -d ecommerce_warehouse -f sql/04_create_fact_tables.sql
```

### 5. ETL for Dimensions & Facts
```bash
psql -U postgres -d ecommerce_warehouse -f sql/05_etl_dim_facts.sql
```

### 6. Apply SCD Upserts
```bash
psql -U postgres -d ecommerce_warehouse -f sql/06_scd_upserts.sql
```

### 7. Add Constraints & Indexes
```bash
psql -U postgres -d ecommerce_warehouse -f sql/07_add_constraints_indexes.sql
```

### 8. Run Analytics Queries
```bash
psql -U postgres -d ecommerce_warehouse -f sql/ANALYTICS.sql
```

*Tip: Use all_scripts_combined.sql to execute everything in one shot.*

## Data Model & ERD
- **Dimensions**: dim_customer, dim_product, dim_seller, dim_date, dim_warehouse.
- **Facts**: fact_orders, fact_order_items, fact_payments, fact_reviews, fact_shipments.
- **ERD**: See docs/erd_diagram.jpeg for a visual representation.

Key elements:
- Surrogate keys and SCD Type 2 for historical tracking.
- Foreign keys linking dimensions to facts.
- SCD metadata columns (effective_start_date, effective_end_date, is_current).

## Advanced Features

### SCD Type 2
- Managed by 06_scd_upserts.sql for versioning dim_customer and dim_warehouse.

### Analytics Queries
- ANALYTICS.sql includes advanced queries (rolling averages, churn, cross-sell).

### Performance
- Indexes on all primary/foreign keys, plus partial indexes for statuses (e.g., delivered).
- Optional partitioning and materialized views for very large data sets.

### Scalability
- Incremental loads or real-time streaming can be set up with triggers or external tools (e.g., Kafka).

## Power BI Dashboard
A key deliverable is the Power BI report (ecommerce.pbix) and its published dashboard.

### Objective
Analyze e-commerce operations from 2016-2018 (via the Olist dataset + synthetic shipping data) to derive insights on:
- Product performance
- Geographic sales distribution
- Shipping costs & delivery times
- Payment trends

### Data Modeling in Power BI
**Tables**:
- **Fact**: fact_orders, fact_order_items, fact_payments, fact_shipments
- **Dimensions**: dim_date, dim_customer, dim_product, dim_category, dim_seller, dim_geolocation, dim_warehouse

**Relationships**:
- 1-to-many from fact_orders to other fact tables (via order_key).
- Surrogate keys linking each dimension to the facts.

**Filters**:
- Typically focusing on fact_orders.order_status = "delivered".

### Key Visualizations

#### Product Category Sales (Treemap)
- Visualizes total revenue by category size.
- Helps identify top-selling categories.

#### Geospatial Sales Map
- Dots sized by revenue, placed on a map of Brazil.
- Highlights geographical concentration (e.g., major cities).

#### Shipping Cost vs. Time (Scatter Chart)
- Plots average shipping cost against delivery time.
- Useful for detecting inefficient shipping lanes or warehouses.

#### Payment Method Trends (Area or Line Chart)
- Shows how payment methods (credit card, boleto, voucher) evolve over time.
- Guides marketing and payment processing decisions.

### Dashboard Layout
Published to Power BI Service as "E-commerce Dashboard":
- **Top-Left**: Product Category Sales (Treemap)
- **Top-Right**: Geospatial Sales Map
- **Bottom-Left**: Shipping Analysis (Scatter)
- **Bottom-Right**: Payment Method Trends (Line/Area Chart)
- **Slicers**: Year, product categories, or others to filter across all visuals.

### Usage Instructions
1. Open ecommerce.pbix in Power BI Desktop (or view in Power BI Service if published).
2. Use Slicers to filter year, product category, etc.
3. Pin Visuals to your custom dashboard in Power BI Service for a consolidated view.
4. Share with stakeholders or export to PDF/PowerPoint.

## Business Value
This project enables stakeholders to make data-driven decisions:
- **Merchandising & Inventory**: Identify best-selling categories and optimize product assortment.
- **Logistics**: Examine shipping times and costs to refine delivery networks.
- **Regional Strategy**: Pinpoint high-revenue geographies for targeted marketing or expansion.
- **Payments**: Track payment trends to align with customer preferences.

## Future Enhancements
- **Real Shipping Data**: Replace synthetic shipment data for more accurate operational analysis.
- **Customer Segmentation**: Add visuals for customer lifetime value or retention/churn.
- **Forecasting**: Implement predictive modeling (sales, demand) using Power BI's AI or external ML solutions.
- **Security & Access Control**: Implement role-based security for read-only analysts.

## Contributing
1. Fork the repository.
2. Create a feature branch for your changes.
3. Submit a Pull Request for review.
4. Open an Issue for major suggestions or architecture changes.

## Contact
- **Author**: Muhammad Hamid Ahmed Dastgir
- **Website**: hamiddastgir.com
- **Email**: hamiddastgirwork@gmail.com
- **Date**: March 13, 2025

> "Data is a precious thing and will last longer than the systems themselves." – Tim Berners-Lee