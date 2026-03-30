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
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
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
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
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
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
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
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
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
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
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
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
SHOW ERRORS;
CALL DataWarehouse_bronze.log_end('erp_PX_CAT_G1V2');
SET @endtime = NOW();
SELECT CONCAT('erp_PX_CAT_G1V2 loaded in ', TIMESTAMPDIFF(SECOND, @starttime, @endtime), ' seconds.') AS 'Execution Log';

-- Progress tracking
SELECT * FROM DataWarehouse_bronze.load_log ORDER BY loaded_at DESC;

-- Errors only
SELECT * FROM DataWarehouse_bronze.error_log ORDER BY logged_at DESC;
