-- ============================================================
-- SILVER LAYER — DATA QUALITY CHECKS
-- ============================================================



-- ============================================================
-- Table: crm_cust_info
-- ============================================================

-- [1] Nulls or duplicates in primary key
--     Expected: 0 rows (nulls filtered, duplicates deduped by ROW_NUMBER)
SELECT 
    cst_id, 
    COUNT(*) AS duplicate_count
FROM DataWarehouse_silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- [2] Unwanted spaces in name fields
--     Expected: 0 rows (TRIM applied in transformation)
SELECT cst_id, cst_firstname, cst_lastname
FROM DataWarehouse_silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname);

-- [3] Null name fields
--     Expected: 0 rows
SELECT cst_id, cst_firstname, cst_lastname
FROM DataWarehouse_silver.crm_cust_info
WHERE cst_firstname IS NULL 
   OR cst_lastname  IS NULL;

-- [4] Data standardization: marital status
--     Expected: only 'Single', 'Married', 'n/a'
SELECT DISTINCT cst_marital_status
FROM DataWarehouse_silver.crm_cust_info;

-- [5] Data standardization: gender
--     Expected: only 'Male', 'Female', 'n/a'
SELECT DISTINCT cst_gndr
FROM DataWarehouse_silver.crm_cust_info;

-- [6] Invalid or future create dates
--     Expected: 0 rows
SELECT cst_id, cst_create_date
FROM DataWarehouse_silver.crm_cust_info
WHERE cst_create_date < '1900-01-01'
   OR cst_create_date > NOW()
   OR cst_create_date IS NULL;

-- [7] Null customer key
--     Expected: 0 rows
SELECT cst_id, cst_key
FROM DataWarehouse_silver.crm_cust_info
WHERE cst_key IS NULL OR TRIM(cst_key) = '';



-- ============================================================
-- Table: crm_prd_info
-- ============================================================

-- [1] Nulls or duplicates in primary key
--     Expected: 0 rows
SELECT 
    prd_id, 
    COUNT(*) AS duplicate_count
FROM DataWarehouse_silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- [2] Unwanted spaces in product name
--     Expected: 0 rows
SELECT prd_id, prd_nm
FROM DataWarehouse_silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- [3] Null product name or key
--     Expected: 0 rows
SELECT prd_id, prd_key, prd_nm
FROM DataWarehouse_silver.crm_prd_info
WHERE prd_nm  IS NULL OR TRIM(prd_nm)  = ''
   OR prd_key IS NULL OR TRIM(prd_key) = '';

-- [4] Nulls or negatives in cost
--     Expected: 0 rows (IFNULL replaces nulls with 0)
SELECT prd_id, prd_nm, prd_cost
FROM DataWarehouse_silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- [5] Data standardization: product line
--     Expected: only 'Mountain', 'Road', 'Other Sales', 'Touring', 'n/a'
SELECT DISTINCT prd_line
FROM DataWarehouse_silver.crm_prd_info;

-- [6] Invalid date range: end date before start date
--     Expected: 0 rows (LEAD window function fills end dates correctly)
SELECT prd_id, prd_key, prd_start_dt, prd_end_dt
FROM DataWarehouse_silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL
  AND prd_end_dt < prd_start_dt;

-- [7] Null start dates
--     Expected: 0 rows
SELECT prd_id, prd_key, prd_start_dt
FROM DataWarehouse_silver.crm_prd_info
WHERE prd_start_dt IS NULL;

-- [8] cat_id format check (should follow XX_XX pattern after transformation)
--     Expected: 0 rows
SELECT prd_id, cat_id
FROM DataWarehouse_silver.crm_prd_info
WHERE cat_id IS NULL 
   OR cat_id NOT REGEXP '^[A-Z]{2}_[A-Z]{2}$';



-- ============================================================
-- Table: crm_sales_details
-- ============================================================

-- [1] Nulls or duplicates in primary key
--     Expected: 0 rows
SELECT 
    sls_ord_num, 
    COUNT(*) AS duplicate_count
FROM DataWarehouse_silver.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL;

-- [2] Null foreign keys
--     Expected: 0 rows
SELECT sls_ord_num, sls_prd_key, sls_cust_id
FROM DataWarehouse_silver.crm_sales_details
WHERE sls_prd_key IS NULL OR TRIM(sls_prd_key) = ''
   OR sls_cust_id IS NULL;

-- [3] Invalid date order: order date after ship or due date
--     Expected: 0 rows
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM DataWarehouse_silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- [4] Out of range dates
--     Expected: 0 rows
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM DataWarehouse_silver.crm_sales_details
WHERE sls_order_dt < '1990-01-01' OR sls_order_dt > '2050-01-01'
   OR sls_ship_dt  < '1990-01-01' OR sls_ship_dt  > '2050-01-01'
   OR sls_due_dt   < '1990-01-01' OR sls_due_dt   > '2050-01-01';

-- [5] Ship date after due date (logically invalid)
--     Expected: 0 rows
SELECT sls_ord_num, sls_ship_dt, sls_due_dt
FROM DataWarehouse_silver.crm_sales_details
WHERE sls_ship_dt > sls_due_dt;

-- [6] Data consistency: sales must equal quantity * price
--     Expected: 0 rows (recalculated in silver transformation)
SELECT 
    sls_ord_num,
    sls_sales,
    sls_quantity,
    sls_price,
    sls_quantity * sls_price AS expected_sales
FROM DataWarehouse_silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales    IS NULL OR sls_sales    <= 0
   OR sls_quantity IS NULL OR sls_quantity <= 0
   OR sls_price    IS NULL OR sls_price    <= 0
ORDER BY sls_sales, sls_quantity, sls_price;



-- ============================================================
-- Table: erp_CUST_AZ12
-- ============================================================

-- [1] Nulls or duplicates in primary key
--     Expected: 0 rows
SELECT 
    cid, 
    COUNT(*) AS duplicate_count
FROM DataWarehouse_silver.erp_CUST_AZ12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

-- [2] NAS prefix should be fully stripped
--     Expected: 0 rows (all 11,042 rows had NAS prefix in bronze)
SELECT cid
FROM DataWarehouse_silver.erp_CUST_AZ12
WHERE cid LIKE 'NAS%';

-- [3] Future birth dates should be nulled out
--     Expected: 0 rows (found future dates like 2050-07-06 in bronze)
SELECT cid, bdate
FROM DataWarehouse_silver.erp_CUST_AZ12
WHERE bdate > NOW();

-- [4] Unrealistically old birth dates
--     Expected: 0 rows
SELECT cid, bdate
FROM DataWarehouse_silver.erp_CUST_AZ12
WHERE bdate < '1924-01-01';

-- [5] Data standardization: gender
--     Expected: only 'Male', 'Female', 'n/a'
--     (bronze had mixed: M, Male, M , F, Female, F , empty)
SELECT DISTINCT gen
FROM DataWarehouse_silver.erp_CUST_AZ12;

-- [6] Unwanted spaces in gender after transformation
--     Expected: 0 rows
SELECT cid, gen
FROM DataWarehouse_silver.erp_CUST_AZ12
WHERE gen != TRIM(gen);



-- ============================================================
-- Table: erp_LOC_A101
-- ============================================================

-- [1] Nulls or duplicates in primary key
--     Expected: 0 rows
SELECT 
    cid, 
    COUNT(*) AS duplicate_count
FROM DataWarehouse_silver.erp_LOC_A101
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

-- [2] Dashes should be fully removed from customer id
--     Expected: 0 rows (all rows had AW-XXXXXXXX format in bronze)
SELECT cid
FROM DataWarehouse_silver.erp_LOC_A101
WHERE cid LIKE '%-%';

-- [3] Data standardization: country
--     Expected: only full country names or 'n/a'
--     (bronze had: DE, US, USA, Germany, United States, empty, spaces)
SELECT DISTINCT cntry
FROM DataWarehouse_silver.erp_LOC_A101;

-- [4] Nulls or empty country values
--     Expected: 0 rows (empty values replaced with n/a in transformation)
SELECT cid, cntry
FROM DataWarehouse_silver.erp_LOC_A101
WHERE cntry IS NULL OR TRIM(cntry) = '';

-- [5] Abbreviated country codes still present (not fully standardized)
--     Expected: 0 rows
SELECT cid, cntry
FROM DataWarehouse_silver.erp_LOC_A101
WHERE cntry IN ('DE', 'US', 'USA', 'UK');



-- ============================================================
-- Table: erp_PX_CAT_G1V2
-- ============================================================

-- [1] Nulls or duplicates in primary key
--     Expected: 0 rows
SELECT 
    id, 
    COUNT(*) AS duplicate_count
FROM DataWarehouse_silver.erp_PX_CAT_G1V2
GROUP BY id
HAVING COUNT(*) > 1 OR id IS NULL;

-- [2] Unwanted spaces in category and subcategory
--     Expected: 0 rows
SELECT id, cat, subcat
FROM DataWarehouse_silver.erp_PX_CAT_G1V2
WHERE cat    != TRIM(cat)
   OR subcat != TRIM(subcat);

-- [3] Null category or subcategory
--     Expected: 0 rows
SELECT id, cat, subcat
FROM DataWarehouse_silver.erp_PX_CAT_G1V2
WHERE cat    IS NULL OR TRIM(cat)    = ''
   OR subcat IS NULL OR TRIM(subcat) = '';

-- [4] Data standardization: maintenance
--     Expected: only 'Yes', 'No', 'n/a'
--     (bronze had hidden \r characters: 'Yes\r', 'No\r')
SELECT DISTINCT maintenance
FROM DataWarehouse_silver.erp_PX_CAT_G1V2;

-- [5] Hidden characters still present in maintenance
--     Expected: 0 rows
SELECT id, maintenance
FROM DataWarehouse_silver.erp_PX_CAT_G1V2
WHERE maintenance != TRIM(maintenance)
   OR maintenance REGEXP '[^a-zA-Z/]';

-- [6] Null maintenance values
--     Expected: 0 rows
SELECT id, maintenance
FROM DataWarehouse_silver.erp_PX_CAT_G1V2
WHERE maintenance IS NULL OR TRIM(maintenance) = '';
