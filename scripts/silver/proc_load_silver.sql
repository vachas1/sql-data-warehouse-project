DELIMITER //

DROP PROCEDURE IF EXISTS DataWarehouse_silver.load_silver //
CREATE PROCEDURE DataWarehouse_silver.load_silver()
BEGIN

    -- ================================================
    -- Variables
    -- ================================================
    DECLARE v_start_time    DATETIME(6);
    DECLARE v_section_start DATETIME(6);
    DECLARE v_end_time      DATETIME(6);
    DECLARE v_error_msg     VARCHAR(500);
    DECLARE v_error_code    INT;

    -- ================================================
    -- Error Handler
    -- ================================================
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg  = MESSAGE_TEXT;

        SELECT CONCAT(
            '================================'      , '\n',
            'ERROR OCCURRED'                        , '\n',
            '================================'      , '\n',
            'Error Code    : ', v_error_code        , '\n',
            'Error Message : ', v_error_msg         , '\n',
            'Time          : ', NOW()               , '\n',
            '================================'
        ) AS error_log;

        INSERT INTO DataWarehouse_silver.load_log (table_name, status, message)
        VALUES ('load_silver', 'FAILED', CONCAT('[', v_error_code, '] ', v_error_msg));
    END;

    -- ================================================
    -- Start
    -- ================================================
    SET v_start_time = NOW(6);
    SELECT '===============================================' AS message;
    SELECT 'Starting silver layer load...'                  AS message;
    SELECT '===============================================' AS message;


    -- ================================================
    -- crm_cust_info
    -- ================================================
    SET v_section_start = NOW(6);
    SELECT '>> Loading: crm_cust_info' AS message;

    TRUNCATE TABLE DataWarehouse_silver.crm_cust_info;
    INSERT INTO DataWarehouse_silver.crm_cust_info(
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT 
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,
        CASE 
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status,
        CASE 
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
    FROM (
        SELECT *, ROW_NUMBER()
        OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM DataWarehouse_bronze.crm_cust_info 
        WHERE cst_id IS NOT NULL
    ) t 
    WHERE flag_last = 1;

    SELECT CONCAT(
        '   crm_cust_info loaded successfully | duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_section_start, NOW(6)) / 1000000, 3),
        's'
    ) AS message;


    -- ================================================
    -- crm_prd_info
    -- ================================================
    SET v_section_start = NOW(6);
    SELECT '>> Loading: crm_prd_info' AS message;

    TRUNCATE TABLE DataWarehouse_silver.crm_prd_info;
    INSERT INTO DataWarehouse_silver.crm_prd_info(
        prd_id, cat_id, prd_key, prd_nm,
        prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key, 7, CHAR_LENGTH(prd_key)) AS prd_key,
        prd_nm,
        IFNULL(prd_cost, 0) AS prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
    FROM DataWarehouse_bronze.crm_prd_info;

    SELECT CONCAT(
        '   crm_prd_info loaded successfully | duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_section_start, NOW(6)) / 1000000, 3),
        's'
    ) AS message;


    -- ================================================
    -- crm_sales_details
    -- ================================================
    SET v_section_start = NOW(6);
    SELECT '>> Loading: crm_sales_details' AS message;

    TRUNCATE TABLE DataWarehouse_silver.crm_sales_details;
    INSERT INTO DataWarehouse_silver.crm_sales_details(
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE 
            WHEN sls_order_dt IS NULL OR sls_order_dt = '0000-00-00' THEN NULL 
            WHEN sls_order_dt < '1990-01-01' OR sls_order_dt > '2050-01-01' THEN NULL
            ELSE sls_order_dt
        END AS sls_order_dt,
        CASE 
            WHEN sls_ship_dt IS NULL OR sls_ship_dt = '0000-00-00' THEN NULL 
            WHEN sls_ship_dt < '1990-01-01' OR sls_ship_dt > '2050-01-01' THEN NULL
            ELSE sls_ship_dt
        END AS sls_ship_dt,
        CASE 
            WHEN sls_due_dt IS NULL OR sls_due_dt = '0000-00-00' THEN NULL 
            WHEN sls_due_dt < '1990-01-01' OR sls_due_dt > '2050-01-01' THEN NULL
            ELSE sls_due_dt
        END AS sls_due_dt,
        CASE 
            WHEN sls_sales IS NULL OR sls_sales <= 0 
                 OR sls_sales != sls_quantity * ABS(COALESCE(NULLIF(sls_price, 0), sls_sales / NULLIF(sls_quantity, 0)))
            THEN sls_quantity * ABS(COALESCE(NULLIF(sls_price, 0), sls_sales / NULLIF(sls_quantity, 0)))
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price
    FROM DataWarehouse_bronze.crm_sales_details;

    SELECT CONCAT(
        '   crm_sales_details loaded successfully | duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_section_start, NOW(6)) / 1000000, 3),
        's'
    ) AS message;


    -- ================================================
    -- erp_CUST_AZ12
    -- ================================================
    SET v_section_start = NOW(6);
    SELECT '>> Loading: erp_CUST_AZ12' AS message;

    TRUNCATE TABLE DataWarehouse_silver.erp_CUST_AZ12;
    INSERT INTO DataWarehouse_silver.erp_CUST_AZ12(cid, bdate, gen)
    SELECT
        CASE 
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, CHAR_LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE 
            WHEN bdate > NOW() THEN NULL
            ELSE bdate
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) LIKE 'F%' THEN 'Female'
            WHEN UPPER(TRIM(gen)) LIKE 'M%' THEN 'Male'
            ELSE 'n/a'
        END AS gen
    FROM DataWarehouse_bronze.erp_CUST_AZ12;

    SELECT CONCAT(
        '   erp_CUST_AZ12 loaded successfully | duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_section_start, NOW(6)) / 1000000, 3),
        's'
    ) AS message;


    -- ================================================
    -- erp_LOC_A101
    -- ================================================
    SET v_section_start = NOW(6);
    SELECT '>> Loading: erp_LOC_A101' AS message;

    TRUNCATE TABLE DataWarehouse_silver.erp_LOC_A101;
    INSERT INTO DataWarehouse_silver.erp_LOC_A101 (cid, cntry)
    SELECT 
        REPLACE(cid, '-', '') AS cid,
        CASE 
            WHEN COALESCE(TRIM(REGEXP_REPLACE(cntry, '[^a-zA-Z ]', '')), '') = '' THEN 'n/a'
            WHEN REGEXP_REPLACE(cntry, '[^a-zA-Z ]', '') LIKE 'DE%' THEN 'Germany'
            WHEN REGEXP_REPLACE(cntry, '[^a-zA-Z ]', '') LIKE 'US%' THEN 'United States'
            ELSE TRIM(REGEXP_REPLACE(cntry, '[^a-zA-Z ]', ''))
        END AS cntry
    FROM DataWarehouse_bronze.erp_LOC_A101;

    SELECT CONCAT(
        '   erp_LOC_A101 loaded successfully | duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_section_start, NOW(6)) / 1000000, 3),
        's'
    ) AS message;


    -- ================================================
    -- erp_PX_CAT_G1V2
    -- ================================================
    SET v_section_start = NOW(6);
    SELECT '>> Loading: erp_PX_CAT_G1V2' AS message;

    TRUNCATE TABLE DataWarehouse_silver.erp_PX_CAT_G1V2;
    INSERT INTO DataWarehouse_silver.erp_PX_CAT_G1V2 (id, cat, subcat, maintenance)
    SELECT 
        id, 
        cat,
        subcat,
        CASE 
            WHEN UPPER(REGEXP_REPLACE(maintenance, '[^a-zA-Z]', '')) = 'YES' THEN 'Yes'
            WHEN UPPER(REGEXP_REPLACE(maintenance, '[^a-zA-Z]', '')) = 'NO'  THEN 'No'
            ELSE 'n/a'
        END AS maintenance
    FROM DataWarehouse_bronze.erp_PX_CAT_G1V2;

    SELECT CONCAT(
        '   erp_PX_CAT_G1V2 loaded successfully | duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_section_start, NOW(6)) / 1000000, 3),
        's'
    ) AS message;


    -- ================================================
    -- Done
    -- ================================================
    SET v_end_time = NOW(6);
    SELECT '===============================================' AS message;
    SELECT CONCAT(
        'Silver layer load complete | total duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000000, 3),
        's'
    ) AS message;
    SELECT '===============================================' AS message;

END //

DELIMITER ;

CALL DataWarehouse_silver.load_silver();
