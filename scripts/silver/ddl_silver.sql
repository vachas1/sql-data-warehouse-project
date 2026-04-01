
DROP TABLE IF EXISTS DataWarehouse_silver.crm_cust_info;
CREATE TABLE DataWarehouse_silver.crm_cust_info(
  cst_id INT,
  cst_key NVARCHAR(50),
  cst_firstname NVARCHAR(50),
  cst_lastname NVARCHAR (50),
  cst_marital_status NVARCHAR(50),
  cst_gndr NVARCHAR(50),
  cst_create_date DATE,
  dwh_Create_date DATETIME(3) DEFAULT NOW(3)
);


-- prd_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
DROP TABLE IF EXISTS DataWarehouse_silver.crm_prd_info;
CREATE TABLE DataWarehouse_silver.crm_prd_info(
  prd_id INT,
  cat_id NVARCHAR(50),
  prd_key NVARCHAR(50),
  prd_nm NVARCHAR(50),
  prd_cost INT,
  prd_line NVARCHAR(50),
  prd_start_dt DATE,
  prd_end_dt DATE,
  dwh_Create_date DATETIME(3) DEFAULT NOW(3)
);

-- sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price
DROP TABLE IF EXISTS DataWarehouse_silver.crm_sales_details;
CREATE TABLE DataWarehouse_silver.crm_sales_details (
  sls_ord_num NVARCHAR(50),
  sls_prd_key NVARCHAR(50),
  sls_cust_id INT,
  sls_order_dt DATE,
  sls_ship_dt DATE,
  sls_due_dt DATE,
  sls_sales INT,
  sls_quantity INT,
  sls_price INT,
  dwh_Create_date DATETIME(3) DEFAULT NOW(3)
);
  
-- CID,BDATE,GEN
DROP TABLE IF EXISTS DataWarehouse_silver.erp_CUST_AZ12;
CREATE TABLE DataWarehouse_silver.erp_CUST_AZ12(
  CID NVARCHAR(50),
  BDATE DATE,
  GEN NVARCHAR(50),
  dwh_Create_date DATETIME(3) DEFAULT NOW(3)
);
-- CID,CNTRY
DROP TABLE IF EXISTS DataWarehouse_silver.erp_LOC_A101;
CREATE TABLE DataWarehouse_silver.erp_LOC_A101(
  CID NVARCHAR(50),
  CNTRY NVARCHAR(50),
  dwh_Create_date DATETIME(3) DEFAULT NOW(3)
);

-- ID,CAT,SUBCAT,MAINTENANCE
DROP TABLE IF EXISTS DataWarehouse_silver.erp_PX_CAT_G1V2;
CREATE TABLE DataWarehouse_silver.erp_PX_CAT_G1V2(
  ID NVARCHAR(50),
  CAT NVARCHAR(50),
  SUBCAT NVARCHAR(50),
  MAINTENANCE NVARCHAR(50),
  dwh_Create_date DATETIME(3) DEFAULT NOW(3)
);





