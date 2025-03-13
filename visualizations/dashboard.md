# E-commerce Dashboard: Olist Sales & Operations Insights

This project delivers a comprehensive Power BI dashboard analyzing e-commerce data from the Olist dataset (2016-2018), enhanced with synthetic shipping data. The dashboard provides actionable insights into product sales, geographic sales distribution, shipping performance, and payment trends. It includes four meticulously crafted visualizations pinned to a shared online dashboard, offering a 360-degree view of e-commerce operations for strategic decision-making.

## Project Overview

- **Objective**: Analyze Olist e-commerce data to uncover insights into product performance, sales distribution, shipping efficiency, and payment trends.
    
- **Data Source**:
    
    - Olist Dataset (2016-2018): Publicly available dataset containing orders, products, customers, sellers, geolocation, payments, and more.
        
    - Synthetic Data: Generated fact_shipments table to simulate shipping details (e.g., shipping costs, delivery dates).
        
- **Tools Used**:
    
    - Power BI Desktop: For data modeling, report creation, and dashboard design.
        
    - Power BI Service: For publishing and sharing the dashboard online.
        
- **Output**:
    
    - Reports: Four pages with individual visualizations.
        
    - Dashboard: "E-commerce Dashboard" in a shared online workspace, with all visuals pinned side by side.
        

## Data Modeling

The dataset was transformed into a star schema in Power BI to ensure efficient querying and relationships for analysis.

### Tables

- **Fact Tables**:
    
    - fact_orders: Core transactional data (orders, dates, statuses).
        
    - fact_order_items: Order details (products, prices, sellers).
        
    - fact_payments: Payment details (payment type, order associations).
        
    - fact_shipments: Synthetic shipping data (shipping costs, dates).
        
- **Dimension Tables**:
    
    - dim_date: Calendar table (dates, years, months).
        
    - dim_customer: Customer details.
        
    - dim_product: Product details.
        
    - dim_category: Product categories (translated to English).
        
    - dim_seller: Seller details.
        
    - dim_geolocation: Geolocation data (latitude, longitude).
        
    - dim_warehouse: Warehouse details (linked to synthetic shipments).
        

### Relationships

- **Core Relationships**:
    
    - fact_orders.order_key → fact_order_items.order_key (1-to-many).
        
    - fact_orders.order_key → fact_payments.order_key (1-to-many).
        
    - fact_orders.order_key → fact_shipments.order_key (1-to-many).
        
- **Dimension Links**:
    
    - fact_orders.order_purchase_date_key → dim_date.date_key.
        
    - fact_order_items.seller_key → dim_seller.seller_key.
        
    - dim_seller.geolocation_key → dim_geolocation.geolocation_key.
        
    - fact_order_items.product_key → dim_product.product_key.
        
    - dim_product.category_key → dim_category.category_key.
        
    - fact_shipments.warehouse_key → dim_warehouse.warehouse_key.
        

### Data Transformations

- **Synthetic Data Generation**: Used Python to create fact_shipments with realistic shipping costs and dates, joined to fact_orders via order_key.
    
- **Date Handling**: Ensured all date keys (e.g., order_purchase_date_key) were linked to dim_date.full_date for time-based analysis.
    
- **Category Translation**: Used dim_category.product_category_name_english for readable product categories.
    
- **Filtering**: Applied a global filter (fact_orders.order_status = "delivered") to focus on completed orders.
    

## Reports

The project includes four report pages, each featuring a single visualization designed to highlight specific insights.

### 1. Product Category Sales Treemap

- **Page**: Product Sales
    
- **Description**: Visualizes total sales revenue by product category. Each box represents a category, sized by revenue, with labels showing the category name and revenue.
    
- **Fields**:
    
    - Group: dim_category.product_category_name_english.
        
    - Values: fact_order_items.price (Sum).
        
- **Formatting**:
    
    - Title: "Sales by Product Category".
        
    - Data Labels: On, Format: "$#,##0".
        
    - Colors: Vibrant diverging palette (blue to orange).
        
- **Insights**:
    
    - Highlights top-selling categories (e.g., "electronics" often dominates).
        
    - Helps prioritize inventory and marketing efforts.
        

### 2. Geospatial Sales Map

- **Page**: Sales Map
    
- **Description**: Displays sales distribution across Brazil using seller locations. Dots are plotted on a map, sized by total sales revenue, showing geographic sales patterns.
    
- **Fields**:
    
    - Latitude: dim_geolocation.latitude.
        
    - Longitude: dim_geolocation.longitude.
        
    - Size: fact_order_items.price (Sum).
        
- **Join Path**:
    
    - fact_order_items → dim_seller (via seller_key) → dim_geolocation (via geolocation_key).
- **Formatting**:
    
    - Map Style: Standard Map (dots).
        
    - Colors: Blue dots, sized by revenue.
        
    - Slicer: dim_date.year (Dropdown).
        
    - Title: "Geospatial Sales Map".
        
- **Insights**:
    
    - Reveals sales concentration (e.g., São Paulo as a major hub).
        
    - Supports regional sales strategies and logistics planning.
        

### 3. Shipping Cost vs. Time Scatter

- **Page**: Shipping Analysis
    
- **Description**: Analyzes shipping performance by plotting delivery time against average shipping cost. Dot size represents order volume, and colors indicate different warehouses.
    
- **Fields**:
    
    - X-Axis: DeliveryDays (custom measure).
        
    - Y-Axis: fact_shipments.shipping_cost (Average).
        
    - Size: fact_shipments.order_key (Count Distinct).
        
    - Legend: dim_warehouse.warehouse_name.
        
- **Custom DAX**:
    
    - DeliveryDays:
    
    ```dax
    DeliveryDays = 
    DATEDIFF(
        MIN('fact_shipments'[ship_date]),
        MAX('fact_shipments'[delivery_date]),
        DAY
    )
    ```
    
- **Formatting**:
    
    - X-Axis: Title: "Delivery Time (Days)".
        
    - Y-Axis: Title: "Average Shipping Cost ($)", Format: "$#,##0.00".
        
    - Title: "Shipping Cost vs. Delivery Time".
        
    - Trend Line: Black, dashed.
        
    - Slicer: dim_date.year (Dropdown).
        
- **Insights**:
    
    - Identifies inefficiencies (e.g., high-cost, slow shipments).
        
    - Useful for optimizing shipping operations.
        

### 4. Payment Method Popularity Over Time

- **Page**: Payment Trends
    
- **Description**: Tracks the evolution of payment methods over time, showing the proportion of orders by payment type (e.g., "credit_card", "boleto").
    
- **Fields**:
    
    - X-Axis: dim_date.full_date (set to "Month").
        
    - Y-Axis: fact_payments.order_key (Count Distinct).
        
    - Legend: fact_payments.payment_type.
        
- **Formatting**:
    
    - Colors: "credit_card" (Blue), "boleto" (Green), "voucher" (Orange), "debit_card" (Purple).
        
    - X-Axis: Title: "Date".
        
    - Y-Axis: Title: "Number of Orders".
        
    - Title: "Payment Method Popularity Over Time".
        
    - Legend: Position → Top.
        
    - Slicer: dim_date.year (Dropdown).
        
- **Insights**:
    
    - Shows payment trends (e.g., growth in "boleto" usage over time).
        
    - Informs payment processing strategies.
        

## Dashboard

The visualizations were pinned to a single dashboard in Power BI Service for a unified view.

- **Dashboard Name**: "E-commerce Dashboard".
    
- **Workspace**: Shared online workspace.
    
- **Layout**: All four visuals are pinned side by side, providing a comprehensive snapshot of e-commerce performance.
    
    - Top Left: Product Category Sales Treemap.
        
    - Top Right: Geospatial Sales Map.
        
    - Bottom Left: Shipping Cost vs. Time Scatter.
        
    - Bottom Right: Payment Method Popularity Over Time.
        
- **Interactivity**: Slicers (e.g., dim_date.year) are pinned, allowing users to filter across all visuals simultaneously.
    

## Usage Instructions

1. **Access the Dashboard**:
    
    - Log in to Power BI Service.
        
    - Navigate to the shared workspace.
        
    - Open the "E-commerce Dashboard".
        
2. **Interact with Visuals**:
    
    - Use the dim_date.year slicer to filter data by year (e.g., 2017).
        
    - Hover over visuals for tooltips (e.g., exact revenue in the Treemap).
        
    - Click on a category in the Treemap to cross-filter other visuals.
        
3. **Share Insights**:
    
    - Share the dashboard link with stakeholders via Power BI Service.
        
    - Export visuals to PDF or PowerPoint for presentations (File → Export).
        

## Technical Notes

- **Date Range**: Olist data spans 2016-2018. Ensure slicers are set within this range for accurate results.
    
- **Synthetic Data**: The fact_shipments table (used in Shipping Analysis) was synthetically generated. While it provides useful insights, real-world shipping data would enhance variability.
    
- **Performance**: The star schema ensures efficient querying. For larger datasets, consider optimizing DAX or aggregating data in the source.
    

## Business Value

This dashboard empowers stakeholders with actionable insights:

- **Product Teams**: Identify top-selling categories for inventory focus (Treemap).
    
- **Regional Managers**: Target high-sales regions for expansion (Map).
    
- **Logistics Teams**: Optimize shipping processes by identifying inefficiencies (Scatter).
    
- **Marketing Teams**: Adapt payment options based on customer preferences (Area Chart).
    

## Future Enhancements

- **Add Real Shipping Data**: Replace synthetic fact_shipments with actual shipping data for more realistic analysis.
    
- **Customer Segmentation**: Include a visual for customer lifetime value or retention analysis.
    
- **Forecasting**: Add predictive analytics (e.g., sales forecasts) using Power BI's AI capabilities.
    

## Contact

For questions, feedback, or contributions, contact:

- **Author**: Muhammad Hamid Ahmed Dastgir
    
- **Email**: [Insert your email here]
    
- **Date**: March 13, 2025