/* loading the data in bulk in mariadb into those 6 tables created before*/


-- Load log table (progress tracking)
CREATE TABLE IF NOT EXISTS DataWarehouse_bronze.load_log (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    table_name  VARCHAR(100),
    status      VARCHAR(10),
    message     VARCHAR(500),
    loaded_at   DATETIME DEFAULT NOW()
);
TRUNCATE TABLE DataWarehouse_bronze.load_log;

-- Error log table (failures only)
CREATE TABLE IF NOT EXISTS DataWarehouse_bronze.error_log (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    table_name  VARCHAR(100),
    error_code  INT,
    error_msg   VARCHAR(500),
    logged_at   DATETIME DEFAULT NOW()
);
TRUNCATE TABLE DataWarehouse_bronze.error_log;

DELIMITER //

DROP PROCEDURE IF EXISTS DataWarehouse_bronze.log_start //
CREATE PROCEDURE DataWarehouse_bronze.log_start(IN tbl VARCHAR(100))
BEGIN
    INSERT INTO DataWarehouse_bronze.load_log (table_name, status, message)
    VALUES (tbl, 'STARTED', 'Load started');
END //

DROP PROCEDURE IF EXISTS DataWarehouse_bronze.log_end //
CREATE PROCEDURE DataWarehouse_bronze.log_end(IN tbl VARCHAR(100))
BEGIN
    INSERT INTO DataWarehouse_bronze.load_log (table_name, status, message)
    VALUES (tbl, 'SUCCESS', 'Load completed successfully');
END //

DROP PROCEDURE IF EXISTS DataWarehouse_bronze.log_error //
CREATE PROCEDURE DataWarehouse_bronze.log_error(IN tbl VARCHAR(100), IN err_code INT, IN err_msg VARCHAR(500))
BEGIN
    -- Insert into error log
    INSERT INTO DataWarehouse_bronze.error_log (table_name, error_code, error_msg)
    VALUES (tbl, err_code, err_msg);

    -- Also update load log to reflect failure
    INSERT INTO DataWarehouse_bronze.load_log (table_name, status, message)
    VALUES (tbl, 'FAILED', err_msg);
END //

DELIMITER ;


-- ===================== CRM_CUST_INFO =====================
SET @starttime = NOW();
CALL DataWarehouse_bronze.log_start('crm_cust_info');
TRUNCATE TABLE DataWarehouse_bronze.crm_cust_info;
LOAD DATA LOCAL INFILE '/home/muzan/Documents/SQLProjects/sql-data-warehouse-project-main/datasets/source_crm/cust_info.csv'
INTO TABLE DataWarehouse_bronze.crm_cust_info
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(@v_cst_id,@v_cst_key,@v_cst_firstname,@v_cst_lastname,@v_cst_marital_status,@v_cst_gndr,@v_cst_create_date)
SET 
    cst_id = NULLIF(TRIM(@v_cst_id), ''),
    cst_key = NULLIF(TRIM(@v_cst_key), ''),
    cst_firstname = NULLIF(TRIM(@v_cst_firstname), ''),
    cst_lastname = NULLIF(TRIM(@v_cst_lastname), ''),
    cst_marital_status = NULLIF(TRIM(@v_cst_marital_status), ''),
    cst_gndr = NULLIF(TRIM(@v_cst_gndr), ''),
    cst_create_date = NULLIF(TRIM(@v_cst_create_date), '');
    
SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('crm_cust_info');
SET @endtime = NOW();
SELECT CONCAT('crm_cust_info loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- ===================== CRM_PRD_INFO =====================
SET @starttime = NOW();
CALL DataWarehouse_bronze.log_start('crm_prd_info');
TRUNCATE TABLE DataWarehouse_bronze.crm_prd_info;
LOAD DATA LOCAL INFILE '/home/muzan/Documents/SQLProjects/sql-data-warehouse-project-main/datasets/source_crm/prd_info.csv'
INTO TABLE DataWarehouse_bronze.crm_prd_info
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(@v_prd_id,@v_prd_key,@v_prd_nm,@v_prd_cost,@v_prd_line,@v_prd_start_dt,@v_prd_end_dt)
SET 
    prd_id = NULLIF(TRIM(@v_prd_id), ''),
    prd_key = NULLIF(TRIM(@v_prd_key), ''),
    prd_nm = NULLIF(TRIM(@v_prd_nm), ''),
    prd_cost = NULLIF(TRIM(@v_prd_cost), ''),
    prd_line = NULLIF(TRIM(@v_prd_line), ''),
    prd_start_dt = NULLIF(TRIM(@v_prd_start_dt), ''),
    prd_end_dt = NULLIF(TRIM(@v_prd_end_dt), '');

SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('crm_prd_info');
SET @endtime = NOW();
SELECT CONCAT('crm_prd_info loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- ===================== CRM_SALES_DETAILS =====================
SET @starttime = NOW();
CALL DataWarehouse_bronze.log_start('crm_sales_details');
TRUNCATE TABLE DataWarehouse_bronze.crm_sales_details;
LOAD DATA LOCAL INFILE '/home/muzan/Documents/SQLProjects/sql-data-warehouse-project-main/datasets/source_crm/sales_details.csv'
INTO TABLE DataWarehouse_bronze.crm_sales_details
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(@v_sls_ord_num,@v_sls_prd_key,@v_sls_cust_id,@v_sls_order_dt,@v_sls_ship_dt,@v_sls_due_dt,@v_sls_sales,@v_sls_quantity,@v_sls_price)
SET 
    sls_ord_num = NULLIF(TRIM(@v_sls_ord_num), ''),
    sls_prd_key = NULLIF(TRIM(@v_sls_prd_key), ''),
    sls_cust_id = NULLIF(TRIM(@v_sls_cust_id), ''),
    sls_order_dt = NULLIF(TRIM(@v_sls_order_dt), ''),
    sls_ship_dt = NULLIF(TRIM(@v_sls_ship_dt), ''),
    sls_due_dt = NULLIF(TRIM(@v_sls_due_dt), ''),
    sls_sales = NULLIF(TRIM(@v_sls_sales), ''),
    sls_quantity = NULLIF(TRIM(@v_sls_quantity), ''),
    sls_price = NULLIF(TRIM(@v_sls_price), '');

SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('crm_sales_details');
SET @endtime = NOW();
SELECT CONCAT('crm_sales_details loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- ===================== ERP_CUST_AZ12 =====================
SET @starttime = NOW();
CALL DataWarehouse_bronze.log_start('erp_CUST_AZ12');
TRUNCATE TABLE DataWarehouse_bronze.erp_CUST_AZ12;
LOAD DATA LOCAL INFILE '/home/muzan/Documents/SQLProjects/sql-data-warehouse-project-main/datasets/source_erp/CUST_AZ12.csv'
INTO TABLE DataWarehouse_bronze.erp_CUST_AZ12
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(@v_CID,@v_BDATE,@v_GEN)
SET 
    CID = NULLIF(TRIM(@v_CID), ''),
    BDATE = NULLIF(TRIM(@v_BDATE), ''),
    GEN = NULLIF(TRIM(@v_GEN), '');
    
SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('erp_CUST_AZ12');
SET @endtime = NOW();
SELECT CONCAT('erp_CUST_AZ12 loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- ===================== ERP_LOC_A101 =====================
SET @starttime = NOW();
CALL DataWarehouse_bronze.log_start('erp_LOC_A101');
TRUNCATE TABLE DataWarehouse_bronze.erp_LOC_A101;
LOAD DATA LOCAL INFILE '/home/muzan/Documents/SQLProjects/sql-data-warehouse-project-main/datasets/source_erp/LOC_A101.csv'
INTO TABLE DataWarehouse_bronze.erp_LOC_A101
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(@v_CID,@v_CNTRY)
SET
    CID = NULLIF(TRIM(@v_CID), ''),
    CNTRY = NULLIF(TRIM(@v_CNTRY), '');
    
SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('erp_LOC_A101');
SET @endtime = NOW();
SELECT CONCAT('erp_LOC_A101 loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- ===================== ERP_PX_CAT_G1V2 =====================
SET @starttime = NOW();
CALL DataWarehouse_bronze.log_start('erp_PX_CAT_G1V2');
TRUNCATE TABLE DataWarehouse_bronze.erp_PX_CAT_G1V2;
LOAD DATA LOCAL INFILE '/home/muzan/Documents/SQLProjects/sql-data-warehouse-project-main/datasets/source_erp/PX_CAT_G1V2.csv'
INTO TABLE DataWarehouse_bronze.erp_PX_CAT_G1V2
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(@v_ID,@v_CAT,@v_SUBCAT,@v_MAINTENANCE)
SET 
    ID = NULLIF(TRIM(@v_ID), ''),
    CAT = NULLIF(TRIM(@v_CAT), ''),
    SUBCAT = NULLIF(TRIM(@v_SUBCAT), ''),
    MAINTENANCE = NULLIF(TRIM(@v_MAINTENANCE), '');

SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('erp_PX_CAT_G1V2');
SET @endtime = NOW();
SELECT CONCAT('erp_PX_CAT_G1V2 loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- Progress tracking
SELECT * FROM DataWarehouse_bronze.load_log ORDER BY loaded_at DESC;

-- Errors only
SELECT * FROM DataWarehouse_bronze.error_log ORDER BY logged_at DESC;
