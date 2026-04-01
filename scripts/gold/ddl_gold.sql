/*
===============================================================================
View: DataWarehouse_gold.dim_customers
-------------------------------------------------------------------------------
Description: 
    Consolidates customer information from CRM and ERP systems into a 
    single dimension. Handles gender normalization and joins location data.
===============================================================================
*/

CREATE OR REPLACE VIEW DataWarehouse_gold.dim_customers AS
SELECT 
    -- Generating a unique Surrogate Key for the Gold layer
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,
    -- Gender logic: Prioritize CRM data, fallback to ERP data if 'n/a'
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM DataWarehouse_silver.crm_cust_info ci
LEFT JOIN DataWarehouse_silver.erp_CUST_AZ12 ca 
    ON ci.cst_key = ca.cid
LEFT JOIN DataWarehouse_silver.erp_LOC_A101 la
    ON ci.cst_key = la.cid;

-------------------------------------------------------------------------------

/*
===============================================================================
View: DataWarehouse_gold.dim_products
-------------------------------------------------------------------------------
Description: 
    Maintains the current product catalog by joining product details with 
    category information. Includes only active products.
===============================================================================
*/

CREATE OR REPLACE VIEW DataWarehouse_gold.dim_products AS
SELECT 
    -- Generating a unique Surrogate Key based on timeline and natural key
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date
FROM DataWarehouse_silver.crm_prd_info pn
LEFT JOIN DataWarehouse_silver.erp_PX_CAT_G1V2 pc 
    ON pn.cat_id = pc.id
-- Filtering out historical/retired products to keep only current catalog
WHERE prd_end_dt IS NULL; 

-------------------------------------------------------------------------------

/*
===============================================================================
View: DataWarehouse_gold.fact_sales
-------------------------------------------------------------------------------
Description: 
    The core fact table representing sales transactions. 
    Connects transaction data to Product and Customer dimensions via 
    Surrogate Keys (Foreign Keys).
===============================================================================
*/

CREATE OR REPLACE VIEW DataWarehouse_gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,   -- Linking to Gold Dimension Surrogate Key
    cu.customer_key,  -- Linking to Gold Dimension Surrogate Key
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM DataWarehouse_silver.crm_sales_details sd
-- Join with dimensions to retrieve the Surrogate Keys
LEFT JOIN DataWarehouse_gold.dim_products pr 
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN DataWarehouse_gold.dim_customers cu 
    ON sd.sls_cust_id = cu.customer_id;
