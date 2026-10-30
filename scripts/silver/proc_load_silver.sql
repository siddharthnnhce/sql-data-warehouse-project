/*
============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
============================================================================
Script Purpose:
  This stored procedure performs the ETL (Extract, Tansform, Load) process to
  populate the 'silver' schema tables from the 'bronze' schema.
Action performed:
  - Truncate Silver tables.
  -Insert transformed and cleansed data from Bronze into silver tables.

Parameters:
  None.
  This stored procedure does not accept any parameter or return any values.

Usage Example:
  EXEC Silver.load_silver.
==============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @start_time_layer DATETIME,
            @end_time_layer DATETIME;

BEGIN TRY

PRINT '========================================================';
PRINT 'Loading Silver Layer';
PRINT '========================================================';

        SET @start_time_layer = GETDATE();
        SET @start_time = GETDATE();

PRINT '>> Truncating Table: silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info';
INSERT INTO silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)
	SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
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
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id is NOT NULL) t where flag_last=1
	SET @end_time =GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'>> -----------------';


    SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	PRINT '>> Inserting Data Into : silver.crm_prd_info';
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
	CASE WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mountain'
		 WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
		 WHEN UPPER(TRIM(prd_line)) ='S' THEN 'Other Sales'
		 WHEN UPPER(TRIM(prd_line)) ='T' THEN 'Touring'
		 ELSE 'N/A'
	END prd_line, -- Map product line code to descriptive values
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt -- Calculate end date as one day before the next start date
	FROM bronze.crm_prd_info
	SET @end_time =GETDATE();
PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
PRINT'>> -----------------';

		

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details
	PRINT '>> Inserting Data Into: silver.crm_sales_details';
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
	sls_quantity,
	CASE WHEN sls_price IS NULL OR sls_price <= 0
			THEN sls_sales / NULLIF(sls_quantity,0)
		ELSE sls_price
	END sls_price---- Derive price if original value is invalid
	FROM bronze.crm_sales_details
	SET @end_time =GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'>> -----------------';
		
        PRINT '>> Loading ERP Tables'

	SET @start_time = GETDATE();
	PRINT'>> Truncating table : silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12
	PRINT'>> Inserting Data Into : silver.erp_cust_az12';
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
	SET @end_time =GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'>> -----------------';

	SET @start_time = GETDATE();
	PRINT'>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101
	PRINT'>> Inserting Data Into : silver.erp_loc_a101'
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
	SET @end_time =GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'>> -----------------';

	SET @start_time = GETDATE();
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
	SET @end_time =GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'>> -----------------';

		 SET @end_time_layer = GETDATE();

		 Print'>> SILVER Layer Load Duration: ' + CAST(DATEDIFF(second,@start_time_layer,@end_time_layer) AS NVARCHAR) + 'second';
		PRINT'-------------------------';
 END TRY
 BEGIN CATCH

        PRINT '========================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT '========================================================';

        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State   : ' + CAST(ERROR_STATE() AS NVARCHAR(10));
        PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        PRINT 'Error Proc    : ' + ISNULL(ERROR_PROCEDURE(),'N/A');

        PRINT '========================================================';

    END CATCH
END

EXEC silver.load_silver;
