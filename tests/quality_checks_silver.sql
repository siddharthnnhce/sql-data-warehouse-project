/*
==========================================================================
Quality Checks
==========================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy,
  and standardization across the 'silver' schemas. It includes check for:
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid data ranges and orders.
  - Data consistency between related fields.

Usage Notes:
  - Run these checks after data loading silver layer.
  - Investigate and resolve any discrepencies found during the checks.
============================================================================
*/

===========================================================================
--checking 'silver.crm_cust_info'
===========================================================================

SELECT * FROM bronze.crm_cust_info


SELECT * FROM bronze.crm_cust_info
WHERE cst_id = 29466

--ROW_NUMBER() - Assign a unique number to each row in a result set, based on a defined order
select *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info WHERE cst_id = 29466

select *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info

SELECT * FROM(
select *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info) R where flag_last !=1 

SELECT * FROM(
select *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info) R where flag_last = 1

SELECT * FROM(
select *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info) R where flag_last = 1 and cst_id = 29466

--check for unwanted spaces
--Expectation: No Results
SELECT cst_firstname from bronze.crm_cust_info

--TRIM() - Removes leading and trailing spaces from a string
SELECT cst_firstname FROM bronze.crm_cust_info WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname FROM bronze.crm_cust_info WHERE cst_lastname != TRIM(cst_lastname)

SELECT cst_id,cst_key, TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastnname,
cst_marital_status,
cst_gndr,
cst_create_date
FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id is NOT NULL) t where flag_last = 1

-- DATA Standarization & Consistency
SELECT DISTINCT cst_gndr
from bronze.crm_cust_info

SELECT cst_id,cst_key, TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastnname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	 ELSE 'N/A'
END cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'N/A'
END cst_gndr,
cst_create_date
FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id is NOT NULL) t where flag_last = 1




PRINT '>> Truncating Table: silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info';
INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
SELECT cst_id,cst_key,TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	 ELSE 'N/A'
END cst_material_status, 
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'N/A'
END cst_gndr,
cst_create_date
FROM (
SELECT *,ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id is NOT NULL) t where flag_last=1

SELECT COUNT(*) FROM silver.crm_cust_info
SELECT COUNT(*) FROM bronze.crm_cust_info

SELECT * FROM silver.crm_cust_info;

================================================================================================
--checking 'silver.crm_prd_info'
================================================================================================
SELECT prd_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

SELECT prd_id, count(*)
from silver.crm_prd_info
GROUP BY prd_id HAVING COUNT(*) > 1 or prd_id is not null

SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

SELECT distinct id from bronze.erp_px_cat_g1v2


SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key,1,5), '-','_') NOT IN
(SELECT distinct id from bronze.erp_px_cat_g1v2)

SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key,1,5), '-','_') NOT IN
(SELECT distinct id from bronze.erp_px_cat_g1v2)

SELECT sls_prd_key from bronze.crm_sales_details

SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LEN(prd_key)) NOT IN
(SELECT sls_prd_key from bronze.crm_sales_details)

SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LEN(prd_key)) IN
(SELECT sls_prd_key from bronze.crm_sales_details)

SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

--ISNULL() Replaces NULL values with a specified replacement value
SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key,
prd_nm,
ISNULL(prd_cost,0),
CASE WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mounatin'
	 WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) ='S' THEN 'Other Sales'
	 WHEN UPPER(TRIM(prd_line)) ='T' THEN 'Touring'
	 ELSE 'N/A'
END prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

--LEAD() - Access values from the next row within a window

SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')

SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509');

SELECT prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key,
prd_nm,
ISNULL(prd_cost,0) As prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mounatin'
	 WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) ='S' THEN 'Other Sales'
	 WHEN UPPER(TRIM(prd_line)) ='T' THEN 'Touring'
	 ELSE 'N/A'
END prd_line,
prd_start_dt,
prd_end_dt,
DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt_test
FROM bronze.crm_prd_info

IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info(
prd_id INT,
cat_id NVARCHAR(50),
prd_key NVARCHAR(50),
prd_nm NVARCHAR(50),
prd_cost INT,
prd_line NVARCHAR(50),
prd_start_dt DATETIME,
prd_end_dt DATETIME,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);

INSERT INTO silver.crm_prd_info (
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)
SELECT prd_id,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id, --Extract category ID
SUBSTRING(prd_key, 7, LEN(prd_key))AS prd_key, -- Extract product key
prd_nm,
ISNULL(prd_cost,0) As prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mounatin'
	 WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) ='S' THEN 'Other Sales'
	 WHEN UPPER(TRIM(prd_line)) ='T' THEN 'Touring'
	 ELSE 'N/A'
END prd_line, -- Map product line code to descriptive values
CAST(prd_start_dt AS DATE) AS prd_start_dt,
DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt -- Calculate end date as one day before the next start date
FROM bronze.crm_prd_info

SELECT count(*) FROM silver.crm_prd_info;

==========================================================================================
--checking 'silver.crm_sales_Details
===========================================================================================
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)


SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key from silver.crm_prd_info)

SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id from silver.crm_cust_info)


SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt<= 0 OR LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END sls_order_dt,
CASE WHEN sls_ship_dt <=0 OR LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END sls_ship_dt,
CASE WHEN sls_due_dt <=0 OR LEN(sls_due_dt)!= 8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_Sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
  ELSE sls_sales
END sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END sls_price,
sls_quantity
FROM bronze.crm_sales_details


IF OBJECT_ID('silver.crm_sales_details','U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details(
sls_ord_num NVARCHAR(50),
sls_prd_key NVARCHAR(50),
sls_cust_id INT,
sls_order_dt DATE,
sls_ship_dt DATE,
sls_due_dt DATE,
sls_sales INT,
sls_quantity INT,
sls_price INT,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);

INSERT INTO silver.crm_sales_details(
sls_ord_num, 
sls_prd_key, 
sls_cust_id,
sls_order_dt, 
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt<= 0 OR LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) --- Data Type Casting
END sls_order_dt,
CASE WHEN sls_ship_dt <=0 OR LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) --- Data Type Casting
END sls_ship_dt,
CASE WHEN sls_due_dt <=0 OR LEN(sls_due_dt)!= 8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)  ---- Data Type Casting
END sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_Sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
  ELSE sls_sales
END sls_sales, --- Recalculating sales if orginal value is missing or incorrect

CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END sls_price,---- Derive price if original value is invalid
sls_quantity
FROM bronze.crm_sales_details

SELECT * FROM silver.crm_sales_details
SELECT COUNT(*) FROM silver.crm_cust_info
SELECT COUNT(*) FROM bronze.crm_cust_info
SELECT COUNT(*) FROM bronze.crm_prd_info
SELECT COUNT(*) FROM bronze.crm_sales_details

===========================================================================================
--checking 'silver.erp_cust_az12
===========================================================================================
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	 ELSE cid
END cid,
CASE WHEN bdate > GETDATE() THEN NULL
	 ELSE bdate
END bdate,
CASE WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
	 WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
	 WHEN gen = 'Male' THEN TRIM(gen)
	 WHEN gen = 'Female' THEN TRIM(gen)
	ELSE 'N/A'
END gen
FROM bronze.erp_cust_az12

SELECT 
cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE cid like '%AW00011000%'
GO
SELECT * FROM silver.crm_cust_info;

IF OBJECT_ID('silver.erp_cust_az12', 'u') IS NOT NULL
	DROP TABLE silver.erp_cust_az12
CREATE TABLE silver.erp_cust_az12(
cid NVARCHAR(50),
bdate DATE,
gen NVARCHAR(50),
dwh_create_date DATETIME2 DEFAULT GETDATE() 
);
INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen)
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- Remove 'NAS' prefix if present
	 ELSE cid
END cid,
CASE WHEN bdate > GETDATE() THEN NULL -- SET future birthdates to NULL
	 ELSE bdate
END bdate,
CASE WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male' --Normalize gender values and handle unknown cases
	 WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
	 WHEN gen = 'Male' THEN TRIM(gen)
	 WHEN gen = 'Female' THEN TRIM(gen)
	ELSE 'N/A'
END gen
FROM bronze.erp_cust_az12

SELECT * FROM silver.erp_cust_az12;

==========================================================================================
--checking 'silver.erp_loc_a101'
==========================================================================================
SELECT 
cid,
cntry
FROM bronze.erp_loc_a101;
GO

SELECT 
REPLACE(cid,'-','') cid,
cntry
FROM bronze.erp_loc_a101 WHERE REPLACE(cid,'-','') NOT IN
(SELECT cst_key FROM silver.crm_cust_info)

-- DATA Standardization & consistency
SELECT DISTINCT cntry
from bronze.erp_loc_a101
ORDER BY cntry;

SELECT 
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
	 ELSE TRIM(cntry)
END cntry
FROM bronze.erp_loc_a101;

SELECT DISTINCT
cntry AS old_cntry,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
	 ELSE TRIM(cntry)
END  cntry
FROM bronze.erp_loc_a101;

INSERT INTO silver.erp_loc_a101
(cid,cntry)
SELECT
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;

SELECT * FROM silver.erp_loc_a101;

=============================================================================
--checking 'silver.erp_px_cat_g1v2'
=============================================================================
SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2;

--Check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat!= TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

--Data Standardization & Consistency
SELECT DISTINCT
cat,
subcat,
id,
maintenance
FROM bronze.erp_px_cat_g1v2;

PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2
(id,cat,subcat,maintenance)
SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.erp_px_cat_g1v2;
