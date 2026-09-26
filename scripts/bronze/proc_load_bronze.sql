/*
===================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===================================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
      - Truncates the bronze tables before loading data.
      - Uses the 'BULK INSERT' command to load data from CSV Files to bronze tables.

Parameters:
    None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bornze;
======================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME, @start_time_layer DATETIME, @end_time_layer DATETIME;
BEGIN TRY
		PRINT '========================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '========================================================';

		IF OBJECT_ID ('bronze.crm_cust_info','U') IS NOT NULL
		DROP TABLE bronze.crm_cust_info;
		CREATE TABLE bronze.crm_cust_info(
		cst_id INT,
		cst_key NVARCHAR(50),
		cst_firstname NVARCHAR(50),
		cst_lastname NVARCHAR(50),
		cst_material_status NVARCHAR(50),
		cst_gndr NVARCHAR(50),
		cst_create_date DATE
		);

		IF OBJECT_ID ('bronze.crm_prd_info','U') IS NOT NULL
		DROP TABLE bronze.crm_prd_info;
		CREATE TABLE bronze.crm_prd_info(
		prd_id INT,
		prd_key NVARCHAR(50),
		prd_nm NVARCHAR(60),
		prd_cost NVARCHAR(50),
		prd_line NVARCHAR(50),
		prd_start_dt DATE,
		prd_end_dt DATE
		);

		IF OBJECT_ID('bronze.crm_sales_details','U') IS NOT NULL
		DROP TABLE bronze.crm_sales_details;
		CREATE TABLE bronze.crm_sales_details(
		sls_ord_num NVARCHAR(50),
		sls_prd_key NVARCHAR(50),
		sls_cust_id INT,
		sls_order_dt INT,
		sls_ship_dt INT,
		sls_due_dt INT,
		sls_sales INT,
		sls_quantity INT,
		sls_price INT
		);

		IF OBJECT_ID('bronze.erp_cust_az12','U') IS NOT NULL
		DROP TABLE bronze.erp_cust_az12;
		CREATE TABLE bronze.erp_cust_az12(
		cid NVARCHAR(50),
		bdate DATE,
		gen NVARCHAR(50)
		)
		IF OBJECT_ID('bronze.erp_loc_a101','U') IS NOT NULL
		DROP TABLE bronze.erp_loc_a101;
		CREATE TABLE bronze.erp_loc_a101(
		cid NVARCHAR(50),
		cntry NVARCHAR(50)
		);

		IF OBJECT_ID('bronze.erp_px_cat_g1v2','U') IS NOT NULL
		DROP TABLE bronze.erp_px_cat_g1v2;
		CREATE TABLE bronze.erp_px_cat_g1v2(
		ID NVARCHAR(50),
		cat NVARCHAR(50),
		subcat NVARCHAR(50),
		maintenance NVARCHAR(50)
		);

		PRINT'=======================================================';
		PRINT'Loading CRM Tables';
		Print'=======================================================';

		SET @start_time_layer = GETDATE();
		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.crm_cust_info ';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT'>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\siddharth ranjan\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time =GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'>> -----------------';

		SET @start_time =GETDATE()
		PRINT'>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT'>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\siddharth ranjan\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'------------------------';

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT'>> Inserting Data Into: crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\siddharth ranjan\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time =GETDATE();
		PRINT'>> Load DURATION: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'------------------------';

		SET @start_time = GETDATE();
		PRINT'=============================================================';
		PRINT'Loading ERP Tables';
		PRINT'=============================================================';

		PRINT'>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT'>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\siddharth ranjan\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time =GETDATE();
		PRINT'>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'------------------------';

		SET @end_time = GETDATE();
		PRINT'>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT'>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\siddharth ranjan\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH(
		FIRSTROW =2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT'>>Load Duration: ' +CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'second';
		PRINT'------------------------';

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT'>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\siddharth ranjan\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
		FIRSTROW =2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'second';
		PRINT'------------------------';
		SET @end_time_layer = GETDATE();
		Print'>> Bronze Layer Load Duration: ' + CAST(DATEDIFF(second,@start_time_layer,@end_time_layer) AS NVARCHAR) + 'second';
		PRINT'-------------------------';
END TRY
BEGIN CATCH
   PRINT'=========================================================';
   PRINT'ERROR OCCURED DURING LOADING BRONZE LAYER';
   PRINT'Error Message' + ERROR_MESSAGE();
   PRINT'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
   PRINT'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
   PRINT'=========================================================';
END CATCH
END




