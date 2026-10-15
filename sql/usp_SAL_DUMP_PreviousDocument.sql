USE [FACTSERPFIRETECH]
GO
/****** Object:  StoredProcedure [dbo].[usp_SAL_DUMP_PreviousDocument]    Script Date: 15-10-2026 2:57:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[usp_SAL_DUMP_PreviousDocument]
/*

			usp_SAL_DUMP_PreviousDocument
			@strFyCode='CFY',
			@strDocType	='SI',
			@strPrevDocType=	'WPL'	,
			@strPrevDocNo	=' ',
			@strAcCode		='',
			@strSubledgerCode	='',
			@strLocationCode	='',	
			@strFmDate=	'2011-04-01',	
			@strToDate	='2019-10-10',	
			@strLoginID	='FACTS'
				
		
*/
	@strFyCode				NVARCHAR( 6),
	@strDocType				NVARCHAR( 6),
	@strPrevDocType	        NVARCHAR( 6),
	@strPrevDocNo			NVARCHAR( 20),
	@strACCode				NVARCHAR( 20),
	@strSubledgerCode		NVARCHAR( 20),	
	@strLocationCode		NVARCHAR( 20),
	@strFmdate				NVARCHAR( 10),
	@strTodate				NVARCHAR( 10),
	@strLoginID				NVARCHAR( 20),
	@strXmlHeaderFormParam	NVARCHAR( MAX)=NULL

AS
		
DECLARE @strSourceDocType		NVARCHAR( 6)
DECLARE @dtFmdate				DATETIME,
		@dtTodate				DATETIME,
		@strHeaderTable			NVARCHAR( 100),
		@strSQLString			NVARCHAR(MAX),
		@strSQLString1			NVARCHAR(MAX),
		@strDefaultLocation		NVARCHAR( 100),
		@strDefaultLocation1	NVARCHAR(20),
		@strDefaultLineItemType	NVARCHAR(20),
		@strDivisionDocNo		NVARCHAR(20),
		@idoc1					INT,
		@strDocNo				NVARCHAR(20),
		@strvariance			NVARCHAR(20),
		@stracdocno				NVARCHAR(20),
		@strjobdocno			NVARCHAR(20)

	    EXEC sp_xml_preparedocument @idoc1 output , @strXmlHeaderFormParam


	   SELECT @strDocNo = SAL_DOCNO
       FROM OPENXML( @idoc1 , 'FACTS/PARAMETERS',2)
       WITH 
       (          
	   
		SAL_AC_DOCNO		NVARCHAR(20),		
		SAL_REFNO			NVARCHAR(20),		
		SAL_DIVN_DOCNO		NVARCHAR(20),		
		SAL_DOCNO			NVARCHAR(20)		
		)

	SELECT 	@strSourceDocType  = dm_source_doctype 
	FROM	document_master 
	WHERE	dm_docno = @strDocType 
 
	SELECT 	@strSourceDocType	= dm_source_doctype,
			@strDivisionDocNo	= dm_divn_docno,
			@stracdocno			= dm_default_ac_docno
	FROM	document_master 
	WHERE	dm_docno = @strDocType 

	SET 	@dtFmdate		= CONVERT( DATETIME, @strFmdate, 120)
	SET 	@dtTodate		=  DATEADD( dd, 1,CONVERT( DATETIME, @strTodate, 120)) 
	 
	  
	SET 	@strPrevDocNo	= NULLIF( ISNULL(  @strPrevDocNo,''),'')
	SET 	@strACCode		= NULLIF( ISNULL(  @strACCode,''),'')
	SET 	@strSubledgerCode = NULLIF( ISNULL(  @strSubledgerCode,''),'')
	SET 	@strLocationCode = NULLIF( ISNULL(  @strLocationCode,''),'')
	
	SELECT	@strHeaderTable		= DM_HEADER_TABLE_NAME,
			@strDefaultLocation	= DM_DEFA_LOCATION
	FROM	document_master
	WHERE	dm_docno = @strPrevDocType

	SELECT @strvariance = 
	CASE WHEN @strPrevDocType = 'BOEXV1' THEN 'BOQVA1'
		 WHEN @strPrevDocType = 'BOEXV2' THEN 'BOQVA2'
		 WHEN @strPrevDocType = 'BOEXV3' THEN 'BOQVA3'
		 WHEN @strPrevDocType = 'BOEXV6' THEN 'BOQVA6' END
	
	SELECT @strjobdocno = 
	CASE WHEN @strDocType LIKE '%10' THEN 'JOB10'
		 WHEN @strDocType LIKE '%20' THEN 'JOB20'
		 WHEN @strDocType LIKE '%30' THEN 'JOB30'
		 WHEN @strDocType LIKE '%40' THEN 'JOB40' 
		 WHEN @strDocType LIKE '%50' THEN 'JOB50' 
		 WHEN @strDocType LIKE '%60' THEN 'JOB60' 
		 END

CREATE 	TABLE #Tmp_Table	
(
		tmp_FyCode							NVARCHAR( 200),
		tmp_DocType							NVARCHAR( 200),
		tmp_docno							NVARCHAR( 200),
		tmp_docdate							DATETIME,
		tmp_MobileNo						NVARCHAR( 200),
		tmp_party							NVARCHAR( 200),
		tmp_description						NVARCHAR( 1000),
		tmp_RefOneNumber					NVARCHAR( 1000),
		tmp_RefOneDate						NVARCHAR( 200),
		tmp_RefTwoNumber					NVARCHAR( 1000),
		tmp_RefTwoDate						NVARCHAR( 200),
		tmp_Location						NVARCHAR( 200),
		tmp_SalesMan						NVARCHAR( 200),
		tmp_division						NVARCHAR( 200),
		tmp_department						NVARCHAR( 200),
		tmp_currency						NVARCHAR( 200), 
		tmp_jobCode							NVARCHAR( 200),
		tmp_jobDesc							NVARCHAR( 1000),
		tmp_departmentDesc					NVARCHAR( 200) ,
		tmp_VAT								NVARCHAR( 200) ,
		 
		tmp_VAT_TREATMENT_DOCNO				NVARCHAR( 200) ,
		tmp_VAT_TREATMENT					NVARCHAR( 200),
		tmp_VAT__RATE_TYPE					NVARCHAR( 200) ,
		tmp_call_log						NVARCHAR( 200) ,
		tmp_main_quotation					NVARCHAR( 200) ,		
		--tmp_ContactName						NVARCHAR( 200),
		tmp_SAL_PREVIOUS_DOCNO				NVARCHAR( 200)--,
		--tmp_ContactCode						NVARCHAR( 200)
)



CREATE 	TABLE #Tmp_Table1	
(
		tmp_FyCode			NVARCHAR( 200),
		tmp_DocType			NVARCHAR( 200),
		tmp_docno			NVARCHAR( 200),
		tmp_docdate			DATETIME,
		tmp_MobileNo		NVARCHAR( 200),
		tmp_party			NVARCHAR( 200),
		tmp_description		NVARCHAR( 1000),
		tmp_RefOneNumber	NVARCHAR( 1000),
		tmp_RefOneDate		NVARCHAR( 200),
		tmp_RefTwoNumber	NVARCHAR( 1000),
		tmp_RefTwoDate		NVARCHAR( 200),
		tmp_Location		NVARCHAR( 200),
		tmp_SalesMan		NVARCHAR( 200),
		tmp_division		NVARCHAR( 200),
		tmp_department		NVARCHAR( 200),
		tmp_currency		NVARCHAR( 200),
		tmp_jobCode			NVARCHAR( 200),
		tmp_jobDesc			NVARCHAR( 1000),
		tmp_call_log		NVARCHAR( 200) ,
		tmp_main_quotation	NVARCHAR( 200) ,
		tmp_amc_job_docno	NVARCHAR( 200),
		tmp_gross_amount	NUMERIC ( 18,3),
		tmp_job_docno		NVARCHAR( 200)
)


CREATE TABLE #DetailTable
(
			SALDET_FYCODE					Nvarchar(6),
			SALDET_DOCTYPE					Nvarchar(6),
			SALDET_DOCNO					Nvarchar(20),
			SALDET_DOCSRNO					Int,
			SALDET_STOCK_DOCTYPE			Nvarchar(6),
			SALDET_STOCK_DOCNO				Nvarchar(50),		
			SALDET_STOCK_DESC				Nvarchar(2000),
			SALDET_LOCATION_DOCNO			Nvarchar(40),
			SALDET_QTY						Numeric(18,3),
			SALDET_UNIT_DOCNO				Nvarchar (6),
			SALDET_RATE						Numeric(18,3),
			SALDET_AMOUNT					Numeric(18,3),
			SALDET_GROSS_AMOUNT				Numeric(18,3),
			SALDET_DISCOUNT_AMOUNT			Numeric(18,3),
			SALDET_DISCOUNT_PERCENT			Numeric(18,3),
			SALDET_CAT_REF					Nvarchar (100),
			SALDET_DOCDATE					Datetime,
			SALDET_EXTENDED_DESC			Nvarchar (2000),
			SALDET_REMARKS					Nvarchar (2000),
			SALDET_CUSTOMER_REFDESC			Nvarchar (100),
			SALDET_BATCH_DOCNO				Nvarchar (20),
			SALDET_OTHER_AMOUNT				Numeric(18,3),
			SALDET_PREVIOUS_FYCODE			Nvarchar (6),
			SALDET_PREVIOUS_DOCTYPE			Nvarchar (6),
			SALDET_PREVIOUS_DOCNO			Nvarchar (20),
			SALDET_PREVIOUS_DOCSRNO			Int,
			SALDET_AFTER_DOC_QTY			Numeric(18,3)	,
			AFTERDOCQTY						Numeric(18,3),
			RESERVEDQTY						Numeric(18,3),
			BEFOREQTY						Numeric(18,3),
			ACMST_DESC						Nvarchar(2000),
			SUBLMST_DESC					Nvarchar(2000),
			FIXED_DIVISION					Nvarchar(2000),
			SALDET_REFONENUMBER				Nvarchar(2000),
			SALDET_REFONEDATE				Datetime,
			SALDET_REFTWODATE				Datetime,
			SALDET_DIVN_DOCNO				Nvarchar(6),
			DivnDesc						Nvarchar(2000),
			SALDET_DEPT_DOCNO				Nvarchar(6),
			DeptDesc						Nvarchar(2000),
			DOCSTAUS						Nvarchar(2000),
			SALDET_SMAN_DOCNO				Nvarchar(20),
			SmanDesc						Nvarchar(250),
			loc_desc						Nvarchar(250),
			SALDET_JOB_DOCNO				Nvarchar (20),
			jobmst_desc						Nvarchar(200),
			SALDET_CURR_DOCNO				Nvarchar(6),
			SALDET_SUBLEDGER_DOCNO			Nvarchar(20),
			SALDET_VAT_PERCENTAGE			NUMERIC(18,3),
			SALDET_VAT_CATEGORY_DOCNO		NVARCHAR(20),
			SALDET_CONTRACT_VALUE			NUMERIC(18,3),
			SAL_DOCUMENT_MODE_DOCNO			NVARCHAR(20),
			SALDET_CUR_CUM_INV_PER			NUMERIC(18,3),
			SALDET_CUR_CUM_INV_AMT			NUMERIC(18,3),
			SALDET_PRE_CUM_INV_PER			NUMERIC(18,3),
			SALDET_PRE_CUM_INV_AMT			NUMERIC(18,3),
			SALDET_INVOICE_PERCENT			NUMERIC(18,3),
			SALDET_WORKCOMPLETION_PERCENT	NUMERIC(18,3),
			SALDET_GROUP_HEADEING1			Nvarchar(2000),
			SALDET_GROUP_HEADEING2			Nvarchar(2000),
			SALDET_BUDGET_QTY				NUMERIC(18,3),
			SALDET_BUDGET_RATE				NUMERIC(18,3),
			SALDET_BUDGET_AMOUNT			NUMERIC(18,3),
			SALDET_COST_DOCNO				Nvarchar(2000)
	)


CREATE TABLE #DetailTable2
(
			SALDET_FYCODE					Nvarchar(6),
			SALDET_DOCTYPE					Nvarchar(6),
			SALDET_DOCNO					Nvarchar(20),
			SALDET_DOCSRNO					Int,
			SALDET_STOCK_DOCTYPE			Nvarchar(6),
			SALDET_STOCK_DOCNO				Nvarchar(50),		
			SALDET_STOCK_DESC				Nvarchar(2000),
			SALDET_LOCATION_DOCNO			Nvarchar(40),
			SALDET_QTY						Numeric(18,3),
			SALDET_UNIT_DOCNO				Nvarchar (6),
			SALDET_RATE						Numeric(18,3),
			SALDET_AMOUNT					Numeric(18,3),
			SALDET_GROSS_AMOUNT				Numeric(18,3),
			SALDET_DISCOUNT_AMOUNT			Numeric(18,3),
			SALDET_DISCOUNT_PERCENT			Numeric(18,3),
			SALDET_CAT_REF					Nvarchar (100),
			SALDET_DOCDATE					Datetime,
			SALDET_EXTENDED_DESC			Nvarchar (2000),
			SALDET_REMARKS					Nvarchar (2000),
			SALDET_CUSTOMER_REFDESC			Nvarchar (100),
			SALDET_BATCH_DOCNO				Nvarchar (20),
			SALDET_OTHER_AMOUNT				Numeric(18,3),
			SALDET_PREVIOUS_FYCODE			Nvarchar (6),
			SALDET_PREVIOUS_DOCTYPE			Nvarchar (6),
			SALDET_PREVIOUS_DOCNO			Nvarchar (20),
			SALDET_PREVIOUS_DOCSRNO			Int,
			SALDET_AFTER_DOC_QTY			Numeric(18,3)	,
			AFTERDOCQTY						Numeric(18,3),
			RESERVEDQTY						Numeric(18,3),
			BEFOREQTY						Numeric(18,3),
			ACMST_DESC						Nvarchar(2000),
			SUBLMST_DESC					Nvarchar(2000),
			FIXED_DIVISION					Nvarchar(2000),
			SALDET_REFONENUMBER				Nvarchar(2000),
			SALDET_REFONEDATE				Datetime,
			SALDET_REFTWODATE				Datetime,
			SALDET_DIVN_DOCNO				Nvarchar(6),
			DivnDesc						Nvarchar(2000),
			SALDET_DEPT_DOCNO				Nvarchar(6),
			DeptDesc						Nvarchar(2000),
			DOCSTAUS						Nvarchar(2000),
			SALDET_SMAN_DOCNO				Nvarchar(20),
			SmanDesc						Nvarchar(250),
			loc_desc						Nvarchar(250),
			SALDET_JOB_DOCNO				Nvarchar (20),
			jobmst_desc						Nvarchar(200),
			SALDET_CURR_DOCNO				Nvarchar(6),
			SALDET_SUBLEDGER_DOCNO			Nvarchar(20),
			SALDET_VAT_CATEGORY_DOCNO		NVARCHAR(20),
			SAL_DOCUMENT_MODE_DOCNO			NVARCHAR(20),
			SALDET_CUR_CUM_INV_PER			NUMERIC(18,3),
			SALDET_CUR_CUM_INV_AMT			NUMERIC(18,3),
			SALDET_PRE_CUM_INV_PER			NUMERIC(18,3),
			SALDET_PRE_CUM_INV_AMT			NUMERIC(18,3),
			SALDET_INVOICE_PERCENT			NUMERIC(18,3),
			SALDET_WORKCOMPLETION_PERCENT	NUMERIC(18,3),
			SALDET_GROUP_HEADEING1			Nvarchar(2000),
			SALDET_GROUP_HEADEING2			Nvarchar(2000),
			SALDET_BUDGET_QTY				NUMERIC(18,3),
			SALDET_BUDGET_RATE				NUMERIC(18,3),
			SALDET_BUDGET_AMOUNT			NUMERIC(18,3),
			SALDET_COST_DOCNO				Nvarchar(2000)
	)

CREATE TABLE #DetailTable4
(
			SALDET_FYCODE					Nvarchar(6),
			SALDET_DOCTYPE					Nvarchar(6),
			SALDET_DOCNO					Nvarchar(20),
			SALDET_DOCSRNO					Int,
			SALDET_STOCK_DOCTYPE			Nvarchar(6),
			SALDET_STOCK_DOCNO				Nvarchar(50),		
			SALDET_STOCK_DESC				Nvarchar(2000),
			SALDET_LOCATION_DOCNO			Nvarchar(40),
			SALDET_QTY						Numeric(18,3),
			SALDET_UNIT_DOCNO				Nvarchar (6),
			SALDET_RATE						Numeric(18,3),
			SALDET_AMOUNT					Numeric(18,3),
			SALDET_GROSS_AMOUNT				Numeric(18,3),
			SALDET_DISCOUNT_AMOUNT			Numeric(18,3),
			SALDET_DISCOUNT_PERCENT			Numeric(18,3),
			SALDET_CAT_REF					Nvarchar (100),
			SALDET_DOCDATE					Datetime,
			SALDET_EXTENDED_DESC			Nvarchar (2000),
			SALDET_REMARKS					Nvarchar (2000),
			SALDET_CUSTOMER_REFDESC			Nvarchar (100),
			SALDET_BATCH_DOCNO				Nvarchar (20),
			SALDET_OTHER_AMOUNT				Numeric(18,3),
			SALDET_PREVIOUS_FYCODE			Nvarchar (6),
			SALDET_PREVIOUS_DOCTYPE			Nvarchar (6),
			SALDET_PREVIOUS_DOCNO			Nvarchar (20),
			SALDET_PREVIOUS_DOCSRNO			Int,
			SALDET_AFTER_DOC_QTY			Numeric(18,3)	,
			AFTERDOCQTY						Numeric(18,3),
			RESERVEDQTY						Numeric(18,3),
			BEFOREQTY						Numeric(18,3),
			ACMST_DESC						Nvarchar(2000),
			SUBLMST_DESC					Nvarchar(2000),
			FIXED_DIVISION					Nvarchar(2000),

			SALDET_REFONENUMBER				Nvarchar(2000),
			SALDET_REFONEDATE				Datetime,
			SALDET_REFTWODATE				Datetime,
			SALDET_DIVN_DOCNO				Nvarchar(6),
			DivnDesc						Nvarchar(2000),
			SALDET_DEPT_DOCNO				Nvarchar(6),
			DeptDesc						Nvarchar(2000),
			DOCSTAUS						Nvarchar(2000),
			SALDET_SMAN_DOCNO				Nvarchar(20),
			SmanDesc						Nvarchar(250),
			loc_desc						Nvarchar(250),
			SALDET_JOB_DOCNO				Nvarchar(100),
			jobmst_desc						Nvarchar(200),
			SALDET_CURR_DOCNO				Nvarchar(6),
			SALDET_SUBLEDGER_DOCNO			Nvarchar(20),
			--VAT
			SALDET_VAT_PERCENTAGE			NUMERIC(18,3),
			SALDET_VAT_CATEGORY_DOCNO		NVARCHAR(20),
			SALDET_CONTRACT_VALUE			NUMERIC(18,3)

	)


CREATE TABLE #DetailTable5
(
			SALDET_FYCODE					Nvarchar(6),
			SALDET_DOCTYPE					Nvarchar(6),
			SALDET_DOCNO					Nvarchar(20),
			SALDET_DOCSRNO					Int,
			SALDET_STOCK_DOCTYPE			Nvarchar(6),
			SALDET_STOCK_DOCNO				Nvarchar(50),		
			SALDET_STOCK_DESC				Nvarchar(2000),
			SALDET_LOCATION_DOCNO			Nvarchar(40),
			SALDET_QTY						Numeric(18,3),
			SALDET_UNIT_DOCNO				Nvarchar (6),
			SALDET_RATE						Numeric(18,3),
			SALDET_AMOUNT					Numeric(18,3),
			SALDET_GROSS_AMOUNT				Numeric(18,3),
			SALDET_DISCOUNT_AMOUNT			Numeric(18,3),
			SALDET_DISCOUNT_PERCENT			Numeric(18,3),
			SALDET_CAT_REF					Nvarchar (100),
			SALDET_DOCDATE					Datetime,
			SALDET_EXTENDED_DESC			Nvarchar (2000),
			SALDET_REMARKS					Nvarchar (2000),
			SALDET_CUSTOMER_REFDESC			Nvarchar (100),
			SALDET_BATCH_DOCNO				Nvarchar (20),
			SALDET_OTHER_AMOUNT				Numeric(18,3),
			SALDET_PREVIOUS_FYCODE			Nvarchar (6),
			SALDET_PREVIOUS_DOCTYPE			Nvarchar (6),
			SALDET_PREVIOUS_DOCNO			Nvarchar (20),
			SALDET_PREVIOUS_DOCSRNO			Int,
			SALDET_AFTER_DOC_QTY			Numeric(18,3)	,
			AFTERDOCQTY						Numeric(18,3),
			RESERVEDQTY						Numeric(18,3),
			BEFOREQTY						Numeric(18,3),
			ACMST_DESC						Nvarchar(2000),
			SUBLMST_DESC					Nvarchar(2000),
			FIXED_DIVISION					Nvarchar(2000),

			SALDET_REFONENUMBER				Nvarchar(2000),
			SALDET_REFONEDATE				Datetime,
			SALDET_REFTWODATE				Datetime,
			SALDET_DIVN_DOCNO				Nvarchar(6),
			DivnDesc						Nvarchar(2000),
			SALDET_DEPT_DOCNO				Nvarchar(6),
			DeptDesc						Nvarchar(2000),
			DOCSTAUS						Nvarchar(2000),
			SALDET_SMAN_DOCNO				Nvarchar(20),
			SmanDesc						Nvarchar(250),
			loc_desc						Nvarchar(250),
			SALDET_JOB_DOCNO				Nvarchar (20),
			jobmst_desc						Nvarchar(200),
			SALDET_CURR_DOCNO				Nvarchar(6),
			SALDET_SUBLEDGER_DOCNO			Nvarchar(20),
			--VAT
			SALDET_VAT_PERCENTAGE			NUMERIC(18,3),
			SALDET_VAT_CATEGORY_DOCNO		NVARCHAR(20),
			SALDET_CONTRACT_VALUE			NUMERIC(18,3)

	)


CREATE TABLE #DetailTable6
(
			SALDET_FYCODE					Nvarchar(6),
			SALDET_DOCTYPE					Nvarchar(6),
			SALDET_DOCNO					Nvarchar(20),
			SALDET_DOCSRNO					Int,
			SALDET_STOCK_DOCTYPE			Nvarchar(6),
			SALDET_STOCK_DOCNO				Nvarchar(50),		
			SALDET_STOCK_DESC				Nvarchar(2000),
			SALDET_LOCATION_DOCNO			Nvarchar(40),
			SALDET_QTY						Numeric(18,3),
			SALDET_UNIT_DOCNO				Nvarchar (6),
			SALDET_RATE						Numeric(18,3),
			SALDET_AMOUNT					Numeric(18,3),
			SALDET_GROSS_AMOUNT				Numeric(18,3),
			SALDET_DISCOUNT_AMOUNT			Numeric(18,3),
			SALDET_DISCOUNT_PERCENT			Numeric(18,3),
			SALDET_CAT_REF					Nvarchar (100),
			SALDET_DOCDATE					Datetime,
			SALDET_EXTENDED_DESC			Nvarchar (2000),
			SALDET_REMARKS					Nvarchar (2000),
			SALDET_CUSTOMER_REFDESC			Nvarchar (100),
			SALDET_BATCH_DOCNO				Nvarchar (20),
			SALDET_AC_DOCNO					Nvarchar (20),
			SALDET_COUNTRY_ORIGIN_DOCNO		Nvarchar (20),
			SALDET_COUNTRY_ORIGIN_DESC		Nvarchar (200),
			SALDET_MESSAGE					Nvarchar (2000),
			SALDET_NOTE						Nvarchar (2000),
			SALDET_CONVERSION_QTY2			Numeric(18,3),
			SALDET_ITEM_BRAND				Nvarchar (200),
			SALDET_ITEM_COUNTRY				Nvarchar (200),
			SALDET_ITEM_SIZE				Nvarchar (200),
			SALDET_ITEM_REF					Nvarchar (200),
			SALDET_SIGN						INT,
			SALDET_GRP_HEADEING1			Nvarchar (2000),
			SALDET_GRP_QTY					Numeric(18,3),
			SALDET_GRP_UNIT					Nvarchar (6),
			SALDET_GRP_CATREF				nVarchar(200),
			SALDET_OTHER_AMOUNT				Numeric(18,3),
			SALDET_PREVIOUS_FYCODE			Nvarchar (6),
			SALDET_PREVIOUS_DOCTYPE			Nvarchar (6),
			SALDET_PREVIOUS_DOCNO			Nvarchar (20),
			SALDET_PREVIOUS_DOCSRNO			Int,
			SALDET_AFTER_DOC_QTY			Numeric(18,3)	,
			AFTERDOCQTY						Numeric(18,3),
			RESERVEDQTY						Numeric(18,3),
			BEFOREQTY						Numeric(18,3),
			ACMST_DESC						Nvarchar(2000),
			SUBLMST_DESC					Nvarchar(2000),
			FIXED_DIVISION					Nvarchar(2000),

			SALDET_REFONENUMBER				Nvarchar(2000),
			SALDET_REFONEDATE				Datetime,
			SALDET_REFTWONUMBER				Nvarchar(2000),
			SALDET_REFTWODATE				Datetime,
			SALDET_DIVN_DOCNO				Nvarchar(6),
			DivnDesc						Nvarchar(2000),
			SALDET_DEPT_DOCNO				Nvarchar(6),
			DeptDesc						Nvarchar(2000),
			DOCSTAUS						Nvarchar(2000),
			SALDET_SMAN_DOCNO				Nvarchar(6),
			SmanDesc						Nvarchar(200),
			loc_desc						Nvarchar(200),
			SALDET_JOB_DOCNO				Nvarchar (20),
			jobmst_desc						Nvarchar(200),
			SALDET_CURR_DOCNO				Nvarchar(6),
			SALDET_SUBLEDGER_DOCNO			Nvarchar(20),						
			SALDET_VAT_PERCENTAGE			NUMERIC(18,3),
			SALDET_VAT_CATEGORY_DOCNO		NVARCHAR(20),
			SALDET_JOB_DOCNO2				NVARCHAR(20)
	)


CREATE TABLE #DetailTable7
(
			SALDET_FYCODE					Nvarchar(6),
			SALDET_DOCTYPE					Nvarchar(6),
			SALDET_DOCNO					Nvarchar(20),
			SALDET_DOCSRNO					Int,
			SALDET_STOCK_DOCTYPE			Nvarchar(6),
			SALDET_STOCK_DOCNO				Nvarchar(50),		
			SALDET_STOCK_DESC				Nvarchar(2000),
			SALDET_LOCATION_DOCNO			Nvarchar(40),
			SALDET_QTY						Numeric(18,3),
			SALDET_UNIT_DOCNO				Nvarchar (6),
			SALDET_RATE						Numeric(18,3),
			SALDET_AMOUNT					Numeric(18,3),
			SALDET_GROSS_AMOUNT				Numeric(18,3),
			SALDET_DISCOUNT_AMOUNT			Numeric(18,3),
			SALDET_DISCOUNT_PERCENT			Numeric(18,3),
			SALDET_CAT_REF					Nvarchar (100),
			SALDET_DOCDATE					Datetime,
			SALDET_EXTENDED_DESC			Nvarchar (2000),
			SALDET_REMARKS					Nvarchar (2000),
			SALDET_CUSTOMER_REFDESC			Nvarchar (100),
			SALDET_BATCH_DOCNO				Nvarchar (20),
			SALDET_OTHER_AMOUNT				Numeric(18,3),
			SALDET_PREVIOUS_FYCODE			Nvarchar (6),
			SALDET_PREVIOUS_DOCTYPE			Nvarchar (6),
			SALDET_PREVIOUS_DOCNO			Nvarchar (20),
			SALDET_PREVIOUS_DOCSRNO			Int,
			SALDET_AFTER_DOC_QTY			Numeric(18,3)	,
			AFTERDOCQTY						Numeric(18,3),
			RESERVEDQTY						Numeric(18,3),
			BEFOREQTY						Numeric(18,3),
			ACMST_DESC						Nvarchar(2000),
			SUBLMST_DESC					Nvarchar(2000),
			FIXED_DIVISION					Nvarchar(2000),

			SALDET_REFONENUMBER				Nvarchar(2000),
			SALDET_REFONEDATE				Datetime,
			SALDET_REFTWODATE				Datetime,
			SALDET_DIVN_DOCNO				Nvarchar(6),
			DivnDesc						Nvarchar(2000),
			SALDET_DEPT_DOCNO				Nvarchar(6),
			DeptDesc						Nvarchar(2000),
			DOCSTAUS						Nvarchar(2000),
			SALDET_SMAN_DOCNO				Nvarchar(20),
			SmanDesc						Nvarchar(250),
			loc_desc						Nvarchar(250),
			SALDET_JOB_DOCNO				Nvarchar (20),
			jobmst_desc						Nvarchar(200),
			SALDET_CURR_DOCNO				Nvarchar(6),
			SALDET_SUBLEDGER_DOCNO			Nvarchar(20),
			--VAT
			SALDET_VAT_PERCENTAGE			NUMERIC(18,3),
			SALDET_VAT_CATEGORY_DOCNO		NVARCHAR(20),
			SALDET_VAT_RATE_TYPE			INT

	)


	SELECT	@strHeaderTable		= DM_HEADER_TABLE_NAME,
			@strDefaultLocation	= DM_DEFA_LOCATION
	FROM	document_master
	WHERE	dm_docno = @strPrevDocType
	
	SELECT	@strDefaultLocation1	= DM_DEFA_LOCATION,
			@strDefaultLineItemType = DM_STOCK_DOCTYPE
	FROM	document_master
	WHERE	dm_docno = @strDocType

	IF @strHeaderTable = 'PURCHASE_HEADER'
	BEGIN			
		INSERT #Tmp_Table1
		(
				tmp_FyCode,
				tmp_DocType,
				tmp_docno,
				tmp_docdate,
						
				tmp_party,
				tmp_description,
						
				tmp_RefOneNumber	,
				tmp_RefOneDate		,
				tmp_RefTwoNumber	,					
				tmp_RefTwoDate		,
						
				tmp_Location		,
				tmp_SalesMan		,
				tmp_division		,
				tmp_department		,
				tmp_currency		,
				tmp_jobCode			,
				tmp_jobDesc	
						 
		)
		SELECT	
				pur_fycode,
				pur_doctype,
				pur_docno, 
				pur_docdate,
				CASE WHEN pur_ac_docno = pur_subledger_docno THEN pur_ac_docno ELSE pur_ac_docno + '-'+pur_subledger_docno END AS pur_ac_docno,
				acmst_desc,	
				head.pur_refno,
				head.pur_refdate,
				head.pur_ref2, 	
				null,
				head.pur_location_docno,
				head.pur_sman_docno, 
				head.pur_divn_docno, 
				head.pur_dept_docno, 
				head.pur_curr_docno,
				pur_job_docno,
				jobmst_desc
		FROM	purchase_header head
		INNER JOIN vw_accountmaster_report on
				acmst_docno = pur_ac_docno AND
				acmst_subledger_docno = ISNULL( PUR_subledger_docno, PUR_ac_docno)
		LEFT OUTER JOIN job_master  on
				jobmst_docno = pur_job_docno
		WHERE	pur_fycode	= @strFyCode AND
				pur_doctype = @strPrevDocType AND 
				pur_docdate >= @dtFmdate AND
				pur_docdate < @dtTodate AND
				pur_ac_docno = ISNULL( @strACCode, pur_ac_docno) AND
				ISNULL( pur_subledger_docno, pur_ac_docno) = ISNULL( @strSubledgerCode, ISNULL( pur_subledger_docno,pur_ac_docno)) AND			
				pur_docno = ISNULL( @strPrevDocNo, pur_docno) AND
				pur_revised_docno	IS	NULL 						
								
		SELECT	tmp_docno			AS DocNo,
				tmp_DocType			AS DocType,
				tmp_docdate			AS Date,
				tmp_party			AS PartyCode,
				tmp_description		AS Party,				 
				tmp_FyCode			AS FyCode,
				tmp_RefOneNumber	AS [RefOneNumber],
				tmp_RefOneDate		AS [RefOneDate],
				tmp_RefTwoNumber	AS RefTwoNumber,	
				tmp_RefTwoDate		AS RefTwoDate	,	
				tmp_Location		AS Location	,	
				tmp_SalesMan		AS SalesMan	,	
				tmp_division		AS	Division	,	
				tmp_department		AS	Department	,	
				tmp_currency		AS	Currency,	
				0					AS [Amount],
				tmp_jobCode			AS JobNo			,
				tmp_jobDesc			AS JobDescription
		FROM	#Tmp_Table1
		ORDER BY tmp_docdate DESC
						
		SELECT	purdet_fycode				AS [Fycode],
				purdet_doctype				AS [DocType],
				purdet_docno				AS [DocNo],
				purdet_docdate				AS [DocDate],
						
				purdet_stock_docno  		AS [Stock Code],
				purdet_stock_desc   		AS [Stock Desc]  ,
				purdet_qty					AS Qty,
				purdet_rate					AS [Rate],
				purdet_amount				AS [Amount],
											
				purdet_docno				AS  SALDET_DOCNO, 
				purdet_docsrno				AS  SALDET_DOCSRNO, 
				purdet_stock_doctype		AS  SALDET_STOCK_DOCTYPE, 
				purdet_stock_docno			AS  SALDET_STOCK_DOCNO, 
				purdet_stock_desc			AS	SALDET_STOCK_DESC, 
				purdet_location_docno		AS  SALDET_LOCATION_DOCNO, 
				purdet_qty					AS  SALDET_QTY, 
				purdet_unit_docno			AS	SALDET_UNIT_DOCNO, 
				purdet_rate					AS 	SALDET_RATE, 
				purdet_amount				AS	SALDET_AMOUNT, 
				purdet_gross_amount			AS  SALDET_GROSS_AMOUNT, 
				purdet_discount_amount		AS 	SALDET_DISCOUNT_AMOUNT, 
				purdet_discount_percent		AS 	SALDET_DISCOUNT_PERCENT, 					
				purdet_fycode				AS 	SALDET_PREVIOUS_FYCODE, 
				purdet_doctype				AS 	SALDET_PREVIOUS_DOCTYPE, 
				purdet_docno				AS 	SALDET_PREVIOUS_DOCNO, 
				purdet_docsrno				AS 	SALDET_PREVIOUS_DOCSRNO, 
				0							AS 	SALDET_AFTER_DOC_QTY, 			
				GETDATE()					AS 	SALDET_DOCDATE, 			
				purdet_extended_desc		AS 	SALDET_EXTENDED_DESC, 
				purdet_fycode				AS 	SALDET_BEFORE_FYCODE, 
				purdet_doctype				AS 	SALDET_BEFORE_DOCTYPE, 
				purdet_docno				AS 	SALDET_BEFORE_DOCNO, 
				purdet_docsrno				AS 	SALDET_BEFORE_DOCSRNO, 
				purdet_remarks				AS 	SALDET_REMARKS, 
				purdet_item_no				AS  SALDET_ITEM_NO,
				''							AS	MATRIX_STRING,
				pur_bid_due_date			as	PUR_BID_DUE_DATE,
				purdet_customer_refno		as	SALDET_CUSTOMER_REFNO,
				purdet_customer_refdesc		AS	SALDET_CUSTOMER_REFDESC,
				purdet_customer_refno		AS 	SALDET_CAT_REF,
						
				pur_ac_docno				AS  SAL_AC_DOCNO,
				pur_subledger_docno			AS  SAL_SUBLEDGER_DOCNO,
				acmst_desc					AS  SUBLMST_DESC,
				pur_contact_docno			AS  SAL_BILL_CONTACT_DOCNO,
				pur_contact_name			AS  SAL_BILL_CONTACT_NAME,
				500000						AS	BEFOREQTY						
		FROM	#Tmp_Table1
		INNER JOIN	purchase_details ON
				purdet_fycode	= tmp_fycode AND
				purdet_doctype	= tmp_doctype AND
				purdet_docno	= tmp_docno
		INNER JOIN purchase_header ON
				pur_fycode		= tmp_fycode AND
				pur_doctype		= tmp_doctype AND
				pur_docno		= tmp_docno
		INNER JOIN vw_accountmaster_report ON
				acmst_docno = pur_ac_docno AND
				acmst_subledger_docno = isnull( pur_subledger_docno, pur_ac_docno)
	END
	IF @strdoctype IN('AEST60','ASQS60')
	BEGIN			
		INSERT #Tmp_Table1
		(
				tmp_FyCode,
				tmp_DocType,
				tmp_docno,
				tmp_docdate,
						
				tmp_party,
				tmp_description,
						
				tmp_RefOneNumber	,
				tmp_RefOneDate		,
				tmp_RefTwoNumber	,					
				tmp_RefTwoDate		,
						
				tmp_Location		,
				tmp_SalesMan		,
				tmp_division		,
				tmp_department		,
				tmp_currency		,
				tmp_jobCode			,
				tmp_jobDesc			,
				tmp_call_log		,
				tmp_main_quotation	,
				tmp_amc_job_docno,
				tmp_gross_amount,
				tmp_job_docno
						 
		)
		SELECT	
				dfes_fycode,
				dfes_doctype,
				dfes_docno, 
				dfes_docdate,
				dfes_subledger_docno,
				acmst_desc,	
				NULL,
				NULL,
				NULL,
				null,
				NULL,
				NULL,
				dfes_divn_docno, 
				dfes_dept_docno, 
				NULL,
				dfes_amc_job_docno,
				jobmst_desc,
				dfes_previous_docno,
				dfes_enquiry_number,
				dfes_amc_job_docno,
				dfes_gross_amount,
				dfes_job_docno
		FROM	data_from_external_source_header head
		INNER JOIN vw_accountmaster_report on
				acmst_docno = dfes_ac_docno AND
				acmst_subledger_docno = ISNULL( dfes_subledger_docno, dfes_ac_docno)
		LEFT OUTER JOIN job_master  on
				jobmst_docno = dfes_job_docno
		WHERE	dfes_fycode	= @strFyCode AND
				dfes_doctype = @strPrevDocType AND 
				dfes_docdate >= @dtFmdate AND
				dfes_docdate < @dtTodate AND
				dfes_ac_docno = ISNULL( @strACCode, dfes_ac_docno) AND
				ISNULL( dfes_subledger_docno, dfes_ac_docno) = ISNULL( @strSubledgerCode, ISNULL( dfes_subledger_docno,dfes_ac_docno)) AND			
				dfes_docno = ISNULL( @strPrevDocNo, dfes_docno) 					
								
		SELECT	tmp_docno			AS DocNo,
				tmp_DocType			AS DocType,
				tmp_docdate			AS Date,
				tmp_party			AS PartyCode,
				tmp_description		AS Party,				 
				tmp_FyCode			AS FyCode,
				tmp_RefOneNumber	AS [RefOneNumber],
				tmp_RefOneDate		AS [RefOneDate],
				tmp_RefTwoNumber	AS RefTwoNumber,	
				tmp_RefTwoDate		AS RefTwoDate	,	
				tmp_Location		AS Location	,	
				tmp_SalesMan		AS SalesMan	,	
				tmp_division		AS Division	,	
				tmp_department		AS Department	,	
				tmp_currency		AS Currency,	
				0					AS [Amount],
				tmp_jobCode			AS JobNo			,
				tmp_jobDesc			AS JobDescription,
				tmp_amc_job_docno	AS [AMC Job Code],
				tmp_gross_amount	AS [Gross Amount],
				tmp_job_docno		AS [Job Code]
		FROM	#Tmp_Table1
		ORDER BY tmp_docdate DESC
						
		SELECT	tmp_fycode						AS [Fycode],
				tmp_doctype						AS [DocType],
				tmp_docno						AS [DocNo],
				tmp_docdate						AS [DocDate],
				500000							AS BEFOREQTY,
				tmp_docno						AS SALDET_DOCNO,
				tmp_docno						AS SALDET_PREVIOUS_DOCNO,
				tmp_doctype						AS SALDET_PREVIOUS_DOCTYPE,
				tmp_fycode						AS SAL_UD_LABEL1,
				tmp_doctype						AS SAL_UD_LABEL2,
				tmp_docno						AS SAL_UD_LABEL3,
				tmp_jobCode						AS SAL_AMC_JOB_DOCNO,
				tmp_call_log					AS SAL_UD_LABEL5,
				tmp_main_quotation				AS SAL_UD_LABEL6,
				tmp_party						AS SAL_SUBLEDGER_DOCNO,
				tmp_description					AS SAL_CUSTOMER_NAME,
				PARTYMST_CURR_DOCNO				AS SAL_CURR_DOCNO,
				CURR_RATE						AS SAL_CURR_RATE,
				PARTYMST_VAT_TRN				AS SAL_VAT_TRN,
				PARTYMST_MOBILE					AS SAL_BILL_MOBILE,
					--AS	SAL_VAT_AMOUNT
				--SAL_VAT_TREATMENT	AS	SAL_VAT_TREATMENT
				PARTYMST_VAT_TREATMENT_DOCNO	AS	SAL_VAT_TREATMENT_DOCNO,
				PARTYMST_VAT_TRN				AS	SAL_VAT_TRN,
				 0								AS	SAL_VAT_RATE_TYPE,
				CASE WHEN PARTYMST_VAT_TREATMENT_DOCNO = 'SR' 
						THEN 1 ELSE 0 END		AS	SAL_VAT_TREATMENT
		FROM	#Tmp_Table1
		LEFT JOIN party_master ON
				PARTYMST_DOCTYPE	=	'AR60'	AND
				PARTYMST_DOCNO		=	tmp_party
		LEFT JOIN currency_master ON
				CURR_DOCNO = PARTYMST_CURR_DOCNO

				--SALES_HEADER

	END
	ELSE IF @strHeaderTable = 'TRANSFER_HEADER'
	BEGIN
	
		SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					TSFDET_FYCODE,
					TSFDET_DOCTYPE,
					TSFDET_DOCNO,
					TSFDET_DOCSRNO,
					TSFDET_STOCK_DOCTYPE,
					TSFDET_STOCK_DOCNO,		
					TSFDET_STOCK_DESC,
					TSFDET_LOCATION_to_DOCNO,
					(TSFDET_qty - ISNULL( TSFDET_after_doc_qty,0)) SALDET_QTY,
					TSFDET_UNIT_DOCNO,
					0 AS TSFDET_RATE,
					0 AS SALDET_AMOUNT,
					0 AS SALDET_GROSS_AMOUNT,
					0 AS SALDET_DISCOUNT_AMOUNT,
					0	TSFDET_DISCOUNT_PERCENT,
					TSFDET_CAT_REF,
					TSFDET_DOCDATE,
					''''											as TSFDET_EXTENDED_DESC,
					''''											as TSFDET_REMARKS,
					''''											as TSFDET_CUSTOMER_REFDESC,
					TSFDET_BATCH_DOCNO								AS TSFDET_BATCH_DOCNO,
					''''											as TSFDET_AC_DOCNO,
					''''											as TSFDET_COUNTRY_ORIGIN_DOCNO,
					''''											as TSFDET_COUNTRY_ORIGIN_DESC,
					''''											as TSFDET_MESSAGE,
					''''											as TSFDET_NOTE,
					0												as TSFDET_CONVERSION_QTY2,
					STK_GRP5_DESC									as TSFDET_ITEM_BRAND,
					''''											AS TSFDET_ITEM_COUNTRY,
					''''											AS TSFDET_ITEM_SIZE,
					''''											AS TSFDET_ITEM_REF,
					0												AS TSFDET_SIGN,
					''''											AS TSFDET_GRP_HEADEING1,
					0												AS TSFDET_GRP_QTY,
					''''											AS TSFDET_GRP_UNIT,
					''''											AS TAFDET_GRP_CATREF,
					0												AS TSFDET_OTHER_AMOUNT,
					TSFDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					TSFDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					TSFDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					TSFDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					TSFDET_QTY - ISNULL( TSFDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					''''											AS ACMST_DESC,
					''''											AS SUBLMST_DESC,
					''''											AS FIXED_DIVISION,

					''''											AS SALDET_REFONENUMBER,
					NULL											AS SALDET_REFONEDATE,
					tsf_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					tsf_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					tsf_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					tsf_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					''''											AS SALDET_JOB_DOCNO,
					''''											AS SALDET_JOBMST_DESC,
					''AED''											AS SALDET_CURR_DOCNO,
					''''											AS SALDET_SUBLEDGER_DOCNO,
					--VAT
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL
			FROM	transfer_Details 
			INNER JOIN TRANSFER_HEADER ON
					TSFDET_FYCODE= TSF_FYCODE AND
					TSFDET_DOCTYPE = TSF_DOCTYPE AND
					TSFDET_DOCNO= TSF_DOCNO 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= tsfdet_stock_doctype AND
					stk.stkmst_docno		= Tsfdet_stock_docno
			left outer  Join stk_grp5 oN
					stk_Grp5_docno = stkmst_grp5
			LEFT OUTER JOIN location_master ON
					loc_docno = TSFdet_location_to_docno 
			LEFT OUTER JOIN salesman_master on
					sman_docno				= TSF_sman_docno		
			LEFT JOIN division_master Div  ON
					TSF_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					TSF_dept_docno			= Dept.dept_docno 
			WHERE	TSF_fycode					= ''' + @strFyCode + ''' AND
					tsfdet_location_to_docno	=	''190''					AND
					tsf_posted_by	IS NOT NULL								AND
					##PREVDOCTYPE##
					##PREVDOCNO##
					##PREVDOCQTY##'
					

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		ELSE 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' TSF_doctype='''+ @strPrevDocType + ''' AND ' )
   
 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		ELSE 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' TSF_docno ='''+ @strPrevDocNo + ''' AND ' )

		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (tsfdet_qty - ISNULL( tsfdet_after_doc_qty,0)) > 0 ' )

		EXEC(@strSQLString  )

							

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable.*, SALDET_LOCATION_DOCNO AS sal_location_docno
		FROM	#DetailTable
		
		ORDER by	saldet_docsrno
 
	END
	--Service Invoice
	IF @strDocType='SVI'
	BEGIN
			
			SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					JOBMST_FYCODE,
					JOBMST_DOCTYPE,
					JOBMST_DOCNO,
					JOBDET_DOCSRNO,
					''SVM'',
					JOBDET_SERVICE_DOCNO,		
					JOBDET_SERVICE_DESC,
					NULL SALDET_LOCATION_DOCNO,
					JOBDET_QTY	SALDET_QTY,
					JOBDET_UNIT_DOCNO SALDET_UNIT_DOCNO,
					JOBDET_RATE SALDET_RATE,
					JOBDET_QTY * JOBDET_RATE AS SALDET_AMOUNT,
					JOBDET_QTY * JOBDET_RATE AS SALDET_GROSS_AMOUNT,
					0 AS SALDET_DISCOUNT_AMOUNT,
					0 AS SALDET_DISCOUNT_PERCENT,
					NULL	SALDET_CAT_REF,
					NULL	SALDET_DOCDATE,
					NULL	SALDET_EXTENDED_DESC,
					NULL	SALDET_REMARKS,
					NULL	SALDET_CUSTOMER_REFDESC,
					NULL	SALDET_BATCH_DOCNO,
					NULL	SALDET_OTHER_AMOUNT,
					JOBMST_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					JOBMST_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					JOBMST_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					JOBDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					0												AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					JOBMST_REFNO									AS SALDET_REFONENUMBER,
					JOBMST_REFDATE									AS SALDET_REFONEDATE,
					NUll											AS SALDET_REFTWODATE,
					JOBMST_DIVN_DOCNO								AS SALDET_DIVN_DOCNO,
					NULL											AS SALDET_DIVN_DESC,
					JOBMST_DEPT_DOCNO								AS SALDET_DEPT_DOCNO,
					NULL											AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					NULL											AS SALDET_SMAN_DOCNO,
					NULL											AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					JOBMST_DOCNO									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					acmst_curr_docno								AS SALDET_CURR_DOCNO,
					jobmst_subledger_docno							AS SALDET_SUBLEDGER_DOCNO,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					null
			FROM	job_master
			LEFT JOIN job_details  ON
				jobmst_fycode	=	jobdet_fycode	AND
				jobmst_doctype	=	jobdet_doctype	AND
				jobmst_docno	=	jobdet_docno
			LEFT OUTER JOIN service_call_log ON
				scl_doctype	=	jobmst_previous_doctype AND 
				scl_docno	=	jobmst_previous_docno 
			LEFT OUTER JOIN account_master ON
				acmst_docno = jobmst_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype = jobmst_ac_docno and
					sublmst_docno = isnull(jobmst_subledger_docno,jobmst_ac_docno) 	
			LEFT JOIN division_master Div  ON
					jobmst_divn_docno = Div.divn_docno 
			WHERE	jobmst_fycode			= ''' + @strFyCode + ''' AND
					jobmst_docdate			>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					jobmst_docdate			< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					jobmst_job_status_docno	<>	''CLOSED''		AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' jobmst_doctype ='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' jobmst_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' jobmst_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' jobmst_docno ='''+ @strPrevDocNo + ''' AND ' )

		SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' jobmst_posted_by is not null ' )


		INSERT INTO USP_SQL_STRING 
		SELECT @strSQLString, NEWID() ,GETDATE()

		PRINt (@strSQLString)
		EXEC(@strSQLString  )
		
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 			#DetailTable.*,
						JOBMST_FYCODE			as 	[Fycode],
						JOBMST_DOCTYPE			as	[DocType],
						JOBMST_DOCNO			as [DocNo],
						JOBMST_DOCDATE			as [DocDate],
	
					
					
						JOBMST_DOCNO			AS SALDET_PREVIOUS_DOCNO,
						JOBMST_DOCTYPE			as SALDET_PREVIOUS_DOCTYPE,
						JOBMST_FYCODE			as  SALDET_PREVIOUS_FYCODE,
						
						JOBMST_DOCNO			AS SAL_PREVIOUS_DOCNO,
						JOBMST_DOCTYPE			as SAL_PREVIOUS_DOCTYPE,
						JOBMST_FYCODE			as  SAL_PREVIOUS_FYCODE,
						JOBMST_AC_DOCNO			as 	SAL_AC_DOCNO,
						JOBMST_SUBLEDGER_DOCNO	as SAL_SUBLEDGER_DOCNO,
										
						JOBMST_SMAN_DOCNO		as  SAL_SMAN_DOCNO,
						JOBMST_JOB_STATUS_DOCNO		as SAL_DOCUMENT_DOCNO,
						JOBMST_GPC_DOCNO			as SAL_GPC_DOCNO,
						JOBMST_CAT_DOCNO			as SAL_CAT_DOCNO,
						JOBMST_DEPT_DOCNO			as SAL_DEPT_DOCNO,
						JOBMST_DIVN_DOCNO			as SAL_DIVN_DOCNO,
						
						JOBMST_UD_LABEL1	as		SAL_UD_LABEL1,
						JOBMST_UD_LABEL2	as		SAL_UD_LABEL2,
						JOBMST_UD_LABEL3	as		SAL_UD_LABEL3,
						JOBMST_UD_LABEL4	as		SAL_UD_LABEL4,	
						JOBMST_UD_LABEL5	as		SAL_UD_LABEL5,
						JOBMST_UD_LABEL6	as		SAL_UD_LABEL6,
						JOBMST_UD_LABEL7		as		SAL_UD_LABEL7,
						JOBMST_UD_LABEL8	as	SAL_UD_LABEL8,
						JOBMST_UD_LABEL9	as SAL_UD_LABEL9,
						JOBMST_UD_LABEL10	as SAL_UD_LABEL10,
						JOBMST_CREATED_BY		as  SAL_CREATED_BY,
						JOBMST_CREATED_TS		as	SAL_CREATED_TS,
						
						JOBMST_JOB_TYPE			as	SAL_JOB_TYPE,
						JOBMST_REFNO			as SAL_REF1,
						JOBMST_REFDATE			as SAL_REFDATE,
						JOBMST_DOCDATE			as SAL_DOCDATE,
						JOBMST_REFNO2			as SAL_REF2,
						JOBMST_SERVICE_TYPE		as SAL_SERVICE_TYPE,
						JOBMST_LOCATION			as SAL_SITE_LOCATION
		FROM	#DetailTable
		INNER JOIN JOB_MASTER ON 
			jobmst_fycode	= saldet_fycode  AND
			jobmst_doctype	= saldet_doctype  AND
			jobmst_docno	= saldet_docno						
		ORDER BY	saldet_docsrno
			
	END	
	IF @strDocType = 'PFI'
	BEGIN
	SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					ISNULL(NULLIF(SALDET_LOCATION_DOCNO,''''),''' + ISNULL(@strDefaultLocation,'') + '''),
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					null
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno = saldet_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno		
		FROM	#DetailTable
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
		 
		
	END	
	IF @strDocType = 'PKL'
	BEGIN
	SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					ISNULL(NULLIF(SALDET_LOCATION_DOCNO,''''),''' + ISNULL(@strDefaultLocation,'') + '''),
					(saldet_qty - ISNULL( saldet_after_doc_qty4,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					((saldet_qty - ISNULL( saldet_after_doc_qty4,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty4,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty4,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty4,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					null
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno = saldet_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty4,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				''   AS sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno		
		FROM	#DetailTable
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
		 
		
	END	
	ELSE IF @strPrevDocType IN ('SE10','SE20','SE30','SE40','SE50','SE60','SET10','SET20','SET30','SET40','SET50','SET60','SES60','SEA60','SEA30','SES30')
	BEGIN
	--raiserror('test',16,1)
		INSERT #Tmp_Table
			(
					tmp_FyCode,
					tmp_DocType,
					tmp_docno,
					tmp_docdate, 
					tmp_party,
					tmp_description, 
					tmp_RefOneNumber	,
					tmp_RefOneDate		,
					tmp_RefTwoNumber	,					
					tmp_RefTwoDate		, 
					tmp_Location		,
					tmp_SalesMan		,
					tmp_division		,
					tmp_department		,
					tmp_currency		, 
					--tmp_jobCode		,
					--tmp_jobDesc		,
					tmp_departmentDesc ,
					tmp_VAT, 
					tmp_VAT_TREATMENT_DOCNO	,
					tmp_VAT_TREATMENT,		
					tmp_VAT__RATE_TYPE,
					--tmp_ContactName,
					tmp_SAL_PREVIOUS_DOCNO
					--tmp_ContactCode
			)
			SELECT	
					sal_fycode,
					sal_doctype,
					sal_docno, 
					sal_docdate,
					CASE WHEN sal_ac_docno = sal_subledger_docno THEN sal_ac_docno ELSE sal_ac_docno + '-'+sal_subledger_docno END AS sal_ac_docno,
					head.SAL_CUSTOMER_NAME,	
					head.sal_refno,
					head.sal_refdate,
					head.sal_ref2, 	
					null,
					head.sal_location_docno,
					head.sal_sman_docno, 
					head.sal_divn_docno, 
					head.sal_dept_docno, 
					head.sal_curr_docno, 
					--sal_job_docno,
					--jobmst_desc ,
					DEPT_DESC ,
					ACMST.ACMST_VAT_TRN  AS SAL_VAT_TRN,
					ISNULL(ACMST_VAT_TREATMENT_DOCNO,'NA')	AS SAL_VAT_TREATMENT_DOCNO,
					ISNULL(TAXTM_TREATMENT,0)				AS SAL_VAT_TREATMENT,
					0										AS SAL_VAT_RATE_TYPE,
					--head.SAL_CONTACT_NAME		AS SAL_BILL_CONTACT_NAME,
					head.sal_docno--,
					--SAL_CONTACT_DOCNO			AS	SAL_BILL_CONTACT_DOCNO 
			FROM	sales_header head
			LEFT JOIN vw_accountmaster_report ACMST ON
					ACMST.acmst_docno = sal_ac_docno AND
					ACMST.acmst_subledger_docno = ISNULL( sal_subledger_docno, sal_ac_docno)
			LEFT OUTER JOIN job_master  ON
					jobmst_docno = sal_job_docno
			LEFT JOIN TAX_TREATMENT_MASTER ON
					TAXTM_DOCNO = ACMST_VAT_TREATMENT_DOCNO	
			--LEFT JOIN user_master salesman on
			--		salesman.user_doctype				=	'USR' AND
			--		salesman.user_default_sman_docno	=	sal_sman_docno				 
			left join DEPARTMENT_MASTER ON
					SAL_DEPT_DOCNO=dept_docno
			WHERE	sal_fycode		= @strFyCode AND
					sal_doctype		= @strPrevDocType AND 
					sal_docdate		>= @dtFmdate AND
					sal_docdate		< @dtTodate AND
					sal_ac_docno	= ISNULL( @strACCode, sal_ac_docno) AND
					ISNULL( sal_subledger_docno, sal_ac_docno) = ISNULL( @strSubledgerCode, ISNULL( sal_subledger_docno,sal_ac_docno)) AND			
					sal_docno		= ISNULL( @strPrevDocNo, sal_docno) 	AND 
					--user_loginid	= 	@strLoginID AND
					isnull(sal_document_status_docno,' ') <>'REJ' AND
					sal_posted_by IS NOT NULL AND
					NOT EXISTS	(
								select	TOP 1  *,
								        sq.sal_bill_tel2		AS SAL_BILL_MOBILE
								from	sales_header sq
								where	sq.sal_fycode			=	@strfycode AND
										sq.sal_doctype			=	@strdoctype AND
										sq.sal_ud_label2		=	head.sal_docno AND
										sq.sal_ud_label1		=	head.sal_doctype		 
								) 	
										
			SELECT	tmp_docno				AS DocNo,
					tmp_DocType				AS DocType,
					tmp_docdate				AS Date,
					tmp_party				AS PartyCode,
					tmp_description			AS Party,				 
					tmp_FyCode				AS FyCode,
					tmp_RefOneNumber		AS [RefOneNumber],
					tmp_RefOneDate			AS [RefOneDate],
					tmp_RefTwoNumber		AS RefTwoNumber,	
					tmp_RefTwoDate			AS RefTwoDate	,	
					tmp_Location			AS Location	,	
					tmp_SalesMan			AS SalesMan	,	
					tmp_division			AS	Division	,	
					tmp_department			AS	Department	,	
					tmp_currency			AS	Currency, 	
					0						AS [Amount],
					--tmp_jobCode				AS JobNo			,
					--tmp_jobDesc				AS JobDescription,
					tmp_departmentDesc      AS DepartmentDesc,
					tmp_VAT					AS  VAT -- ,
					--tmp_ContactName ,
					--tmp_ContactCode    
			FROM	#Tmp_Table
			ORDER BY tmp_docdate DESC

			SELECT	SALDET_FYCODE			AS [Fycode],
					SALDET_DOCTYPE			AS [DocType],
					SALDET_DOCNO			AS [DocNo],
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					'SMNS' AS SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					'1011' AS SALDET_LOCATION_DOCNO,
					(saldet_qty ) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					(saldet_qty ) * SALDET_RATE AS SALDET_AMOUNT,
					(saldet_qty ) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty ) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_AC_DOCNO,
					'''',
					'''',
					SALDET_MESSAGE,
					SALDET_NOTE,
					SALDET_CONVERSION_QTY2,
					SALDET_ITEM_BRAND,
					SALDET_ITEM_COUNTRY,
					SALDET_ITEM_SIZE,
					SALDET_ITEM_REF,
					SALDET_SIGN,
					'''',
					SALDET_GRP_QTY,
					SALDET_GRP_UNIT,
					SALDET_GRP_CATREF,
					SALDET_OTHER_AMOUNT,
					SAL_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					SAL_DOCTYPE										AS SALDET_PREVIOUS_DOCTYPE,
					SAL_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS SALDET_AFTER_DOC_QTY2,
					0												AS SALDET_AFTER_DOC_QTY3,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,

					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					--sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,
					sal_cr_days,
					sal_ac_docno,
					sal_subledger_docno,
					sal_cost_docno,
					--sal_job_docno,
					--sal_ref,
					sal_sman_docno,
					sal_curr_docno,
					CURR_RATE  AS sal_curr_rate,
					sal_narration,
					sal_gross_amount,
					sal_other_amount,
					sal_net_amount,
					sal_location_docno,
					sal_total_qty,
					sal_created_by,
					sal_created_ts,
					sal_doctype AS	sal_ud_label1,
					sal_docno   AS	sal_ud_label2,
					sal_ud_label3,
					sal_ud_label4,
					sal_ud_label5,
					sal_fycode	AS	sal_ud_label8,
					sal_doctype	AS	sal_ud_label9,
					sal_docno	AS	sal_ud_label10,
					sal_ud_letter_text,
					sal_dept_docno,
					sal_divn_docno,
					sal_ref2,
					sal_address,
					sal_qotno,
					0 AS sal_discount_amount,
					sal_discount_percent,
					sal_refno,
					sal_refdate,
					sal_total_amount,
					sal_bid_due_date,
					sal_contact_docno   AS SAL_BILL_CONTACT_DOCNO,
					sal_ship_contact_docno,
					sal_bill_contact_docno,
					sal_ship_address,
					sal_bill_address,
					sal_ship_addr1,
					sal_bill_addr1,
					sal_ship_addr2,
					sal_bill_addr2,
					sal_ship_addr3,
					sal_bill_addr3,
					sal_ship_city,
					sal_bill_city,
					sal_ship_state,
					sal_bill_state,
					sal_ship_country,
					sal_bill_country,
					sal_ship_street,
					sal_bill_street,
					sal_ship_zipcode,
					sal_bill_zipcode,
					sal_ship_mobile,
					sal_bill_tel1					AS SAL_BILL_MOBILE,
					sal_ship_tel1,
					sal_bill_tel1,
					sal_ship_tel2,
					sal_bill_tel2,
					sal_ship_fax,
					--sal_bill_fax,
					sal_ship_email,
					sal_bill_email,
					SAL_DOCNO	AS	SAL_PREVIOUS_DOCNO,
					SAL_DOCTYPE AS	sal_prev_doctype,
					SAL_FYCODE	AS	sal_prev_fycode,
					sal_prev_docdate,
					SAL_PORT_OF_LOADING AS SAL_REFERENCE1,
					sal_reference2,
					sal_reference3,
					sal_paytrm_docno,
					sal_deltrm_docno,
					SAL_CONTACT_NAME AS sal_bill_contact_name,
					sal_ship_contact_name,
					sal_shipto_subledger_docno,
					sal_active_status,
					sal_paytrm_desc,
					sal_deltrm_desc,
					sal_document_status_docno,
					sal_posted_by,
					sal_posted_ts,
					sal_paymode_docno,
					sal_paymode_desc,
					sal_batch_docno,
					sal_tax_percentage,
					sal_tax_amount,
					sal_delivery_date,
					sal_contact_name,
					sal_previous_docno     ,
					sal_ref1,
					sal_sman_desc,
					sal_mob_no,
					sal_payment_mode_docno,
					sal_estimator,
					sal_chasis_no,
					acmst_desc,
					sublmst_desc,
					sal_wt_amount,
					sal_trailer_no,
					sal_customer_name, 
					jobmst_desc,
					dept.DEPT_DESC    ,  
					sal_narration				AS		SAL_SUBJECT  ,
					1  AS SAL_CURR_RATE ,
					sal_bill_fax				AS		SAL_VAT_TRN ,
					0.000						as		SAL_VAT_AMOUNT,
					tmp_VAT_TREATMENT_DOCNO		as		SAL_VAT_TREATMENT_DOCNO,
					tmp_VAT_TREATMENT			as		SAL_VAT_TREATMENT, 
					tmp_VAT__RATE_TYPE			as		SAL_VAT_RATE_TYPE,    
					SAL_PROJ_NAME  ,
					SAL_SMAN_DESC,
					SAL_NOTIFY_PARTY_AC_DOCNO,
					SAL_BILL_MAP				AS  SAL_UD_LABEL6,
					SAL_AWB_NO					AS	SAL_REF,
					SAL_AWB_NO					AS	SAL_BILL_FAX

				FROM	#Tmp_Table 
				INNER JOIN   sales_header  ON 
						sal_fycode			= tmp_FyCode AND
						sal_doctype			= tmp_docType AND
						sal_docno			= tmp_docno 
				LEFT OUTER JOIN sales_details ON
						saldet_fycode		= sal_fycode AND
						saldet_doctype		= sal_doctype AND
						saldet_docno		= sal_docno 	
				LEFT OUTER JOIN location_master ON
						loc_docno			= saldet_location_docno 
				INNER JOIN account_master ON
						acmst_docno			= sal_ac_docno
				LEFT OUTER JOIN subledger_master ON
						sublmst_doctype		= sal_ac_docno AND
						sublmst_docno		= ISNULL( sal_subledger_docno,sal_ac_docno) 
				--left JOIN   vw_accountmaster_report ACMST1 on         
				--		ACMST1.acmst_docno = sal_ac_docno and        
				--		ACMST1.acmst_subledger_docno = isnull( sal_subledger_docno,sal_ac_docno) 			
				LEFT OUTER JOIN salesman_master on
						sman_docno			= sal_sman_docno		
				LEFT JOIN division_master Div  ON
						sal_divn_docno		= div.divn_docno 
				LEFT JOIN department_master  Dept  ON
						sal_dept_docno		= Dept.dept_docno 
				LEFT OUTER JOIN job_master   on
						sal_job_docno =jobmst_docno	  
				LEFT JOIN currency_master	ON
					curr_docno =	sal_curr_docno	 
		
END
	IF @strDocType = 'SQ10'
	BEGIN
	
		SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					CASE WHEN '''+@strDocType+''' =''SI'' then SALDET_LOCATION_DOCNO else
					ISNULL(NULLIF(SALDET_LOCATION_DOCNO,''''),''' + ISNULL(@strDefaultLocation,'') + ''') end AS SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					null
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL 
				
					'
					--	AND
					--##PREVDOCTYPE##
					--##ACDOCNO##
					--##SUBLEDGERACDOCNO##
					--##PREVDOCNO##
					--##POSTEDBY##
					--##PREVDOCQTY##

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno		
		FROM	#DetailTable
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END
	IF @strDocType = 'SQ20'
	BEGIN
	
		SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					SAL_FYCODE,
					SAL_DOCTYPE,
					SAL_DOCNO,
					1  as SALDET_DOCSRNO ,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					0,
					0,
					0,
					0,
					0,
					SALDET_CAT_REF,
					SAL_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SAL_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SAL_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SAL_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					1									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					0	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					null
			FROM	 SALES_HEADER
			LEFT JOIN SALES_DETAILS ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			LEFT JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			--##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					sal_doctype = ''' + @strPrevDocType + '''  '
					--##PREVDOCTYPE## '
					--##ACDOCNO##
					--##SUBLEDGERACDOCNO##
					--##PREVDOCNO##
					--##POSTEDBY##
					--##PREVDOCQTY##

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + '''' )

		--IF @strACCode is null			    
		--	SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 	--	IF @strSubledgerCode is null			    
		--	SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 	--	IF @strPrevDocNo is null			    
		--	SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		----IF LEFT(LTRIM(@strDocType),2) = 'SR'
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		----Else 
		----	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		--SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		--IF @strSourceDocType NOT IN ('DIT')
		--	SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	salDET_docno							AS DocNo,
				salDET_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno		
		FROM	#DetailTable
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END
	IF @strDocType = 'SQ30'
	BEGIN
	
		SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT			
					SAL_FYCODE,
					SAL_DOCTYPE,
					SAL_DOCNO,
					1  as SALDET_DOCSRNO ,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					0,
					0,
					0,
					0,
					0,
					SALDET_CAT_REF,
					SAL_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SAL_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SAL_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SAL_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					1									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					0	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					null
			FROM	 SALES_HEADER
			LEFT JOIN SALES_DETAILS ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			LEFT JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			--##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					sal_doctype = ''' + @strPrevDocType + '''  '
					--##PREVDOCTYPE## '
					--##ACDOCNO##
					--##SUBLEDGERACDOCNO##
					--##PREVDOCNO##
					--##POSTEDBY##
					--##PREVDOCQTY##

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + '''' )

		--IF @strACCode is null			    
		--	SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 	--	IF @strSubledgerCode is null			    
		--	SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 	--	IF @strPrevDocNo is null			    
		--	SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		----IF LEFT(LTRIM(@strDocType),2) = 'SR'
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		----Else 
		----	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		--SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		--IF @strSourceDocType NOT IN ('DIT')
		--	SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	salDET_docno							AS DocNo,
				salDET_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno		
		FROM	#DetailTable
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END
	IF @strDocType IN('SI10','SI20','SI30','SI40','SI50','SI60') and @strPrevDocType like 'PCC%'
	BEGIN
	--raiserror('test',16,1)
		SET @strSQLString = N'INSERT INTo #DetailTable
	
			SELECT	SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					MAX(SALDET_DOCSRNO) ,
					MAX(SALDET_STOCK_DOCTYPE),
					MAX(SALDET_STOCK_DOCNO),		
					CASE WHEN MAX(SAL_DOCUMENT_MODE_DOCNO) = ''00'' THEN ''Advance Invoice'' 
					WHEN MAX(SAL_DOCUMENT_MODE_DOCNO) = ''01'' THEN ''Progressive Invoice''
					WHEN MAX(SAL_DOCUMENT_MODE_DOCNO) = ''91'' THEN ''Final Invoice'' 
					ELSE ''NON STOCK ITEM'' END AS SALDET_STOCK_DESC,
					MAX(SALDET_LOCATION_DOCNO),
					1	AS SALDET_QTY,
					''LS'',
					1,
					SUM(SALDET_AMOUNT)  AS SALDET_AMOUNT,
					SUM(SALDET_AMOUNT)	AS SALDET_GROSS_AMOUNT,
					----SUM(SALDET_AMOUNT)  AS SALDET_GROSS_AMOUNT,
					0 AS SALDET_DISCOUNT_AMOUNT,
					0 AS SALDET_DISCOUNT_PERCENT,
					MAX(SALDET_CAT_REF)	AS SALDET_CAT_REF,
					MAX(SALDET_DOCDATE),
					MAX(SALDET_EXTENDED_DESC),	
					MAX(SALDET_REMARKS),
					MAX(SALDET_CUSTOMER_REFDESC),
					MAX(SALDET_BATCH_DOCNO),
					null,
					SALDET_FYCODE				AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE				AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO				AS SALDET_PREVIOUS_DOCNO,
					MAX(SALDET_DOCSRNO)			AS SALDET_PREVIOUS_DOCSRNO,
					0							AS SALDET_AFTER_DOC_QTY,
					0							AS AFTERDOCQTY,
					0							AS RESERVEDQTY,
					0							AS BEFOREQTY,
					MAX(acmst_DEsc),
					MAX(sublmst_Desc),
					MAX(acmst_divn_docno)		AS FIXED_DIVISION,
					MAX(sal_refno)				AS SALDET_REFONENUMBER,
					MAX(sal_refdate)			AS SALDET_REFONEDATE,
					NUll						AS SALDET_REFTWODATE,
					MAX(sal_divn_docno)			AS SALDET_DIVN_DOCNO,
					MAX(divn_desc)				AS SALDET_DIVN_DESC,
					MAX(sal_dept_docno)			AS SALDET_DEPT_DOCNO,
					MAX(dept_desc)				AS SALDET_DEPT_DESC,
					Null						AS DOCSTAUS,
					MAX(sal_sman_docno)			AS SALDET_SMAN_DOCNO,
					MAX(sman_Desc)				AS SALDET_SMAN_DESC,
					MAX(location_master.loc_desc)	AS SALDET_LOC_DESC,
					MAX(sal_job_docno)			AS SALDET_JOB_DOCNO,
					MAX(jobmst_desc)			AS SALDET_JOBMST_DESC,
					MAX(sal_curr_docno)			AS SALDET_CURR_DOCNO,
					MAX(sal_subledger_docno)	AS SALDET_SUBLEDGER_DOCNO,					
					MAX(saldet_vat_percentage),
					MAX(saldet_vat_category_docno),
					MAX(JOBMST_BUDJ_INCOME) AS SALDET_CONTRACT_VALUE,
					--CASE WHEN MAX(SAL_DOCUMENT_MODE_DOCNO) = ''00'' THEN ''Advance Invoice''
					--WHEN MAX(SAL_DOCUMENT_MODE_DOCNO) = ''01'' THEN ''Progressive Invoice'' 
					--WHEN MAX(SAL_DOCUMENT_MODE_DOCNO) = ''91'' THEN ''Final Invoice'' 
					--ELSE ''NON STOCK ITEM'' END,
					MAX(SAL_DOCUMENT_MODE_DOCNO),
					SUM(SALDET_CUR_CUM_INV_AMT) / MAX(JOBMST_BUDJ_INCOME) * 100 AS  SALDET_CUR_CUM_INV_PER,
					SUM(SALDET_CUR_CUM_INV_AMT) AS SALDET_CUR_CUM_INV_AMT,			
					SUM(ISNULL(SALDET_PRE_CUM_INV_AMT,0.00)) / MAX(JOBMST_BUDJ_INCOME) * 100 AS SALDET_PRE_CUM_INV_PER,
					SUM(ISNULL(SALDET_PRE_CUM_INV_AMT,0.00)) AS SALDET_PRE_CUM_INV_AMT,
					((SUM(SALDET_CUR_CUM_INV_AMT) / MAX(JOBMST_BUDJ_INCOME) * 100) - (SUM(ISNULL(SALDET_PRE_CUM_INV_AMT,0.00)) / MAX(JOBMST_BUDJ_INCOME) * 100)) AS SALDET_INVOICE_PERCENT,
					0 AS SALDET_WORKCOMPLETION_PERCENT,
					0 AS SALDET_GROUP_HEADEING1,
					0 AS SALDET_GROUP_HEADEING2,
					0 AS SALDET_BUDGET_QTY,
					0 AS SALDET_BUDGET_RATE,
					SUM(SALDET_BUDGET_AMOUNT)  AS SALDET_BUDGET_AMOUNT,
					null'
SET @strSQLString = @strSQLString + '
			FROM	sales_details 
			INNER JOIN sales_header ON
					saldet_fycode		= sal_fycode AND
					saldet_doctype		= sal_doctype AND
					saldet_docno		= sal_docno 
			INNER JOIN job_master jm2  on
					jm2.jobmst_doctype	= '''+ @strjobdocno +''' AND
					jm2.jobmst_docno	= sal_job_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno = sal_location_docno 
			LEFT JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
					##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					ISNULL(sal_document_status_docno,''ACT'') not in (''VOID'',''1002'') AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
				GROUP BY saldet_fycode,saldet_doctype,saldet_docno
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--Show only Approved documents
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is NOT NULL AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
		
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty,0)) > 0 ' )

		SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )

		PRINT CAST(@strSQLString as ntext)
		EXEC(@strSQLString  )
			
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc )						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( saldet_refonenumber)				AS [RefNo],
				MAX( saldet_refonedate)					AS [RefDate],
				MAX( smandesc)	 						AS SalesMan,	
				MAX( saldet_job_docno)					AS JobNo,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( saldet_amount)						AS Amount,
				MAX( saldet_curr_docno)					AS Currency,
				Null									AS [Make],
				NUll									AS [Model],
				MAX(saldet_cat_ref)						AS [OldDocNo]
		FROM	#DetailTable
	 
		--WHERE ISNULL(saldet_parent_id,0) = 0
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
  


		SELECT 	 
				#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_ac_docno,
				sal_subledger_docno,
				sales_header.sal_document_mode_docno,
				sal_job_docno,
				sal_document_status_docno,
				sal_ship_street,
				sal_ship_city,
				sal_ship_state,
				sal_ship_zipcode,
				sal_ship_country,
				sal_ship_address,
				sal_location_docno,
				sal_bill_street,
				sal_bill_city,
				sal_bill_state,
				sal_bill_zipcode,
				sal_bill_country,
				sal_bill_address,
				sal_bill_contact_docno,
				sal_bill_contact_name,
				sal_vat_trn,	
				sal_refno,
				sal_refdate,
				sal_cr_days,
				sal_curr_rate,
				sal_net_amount,
				sal_sman_docno,
				sal_curr_docno,
				sal_prev_docno,
				sal_other_amount,
				sal_narration,
			---	sal_docdate,
				sal_discount_percent,
				sal_vat_amount,
				sal_discount_amount,
				sal_gross_amount,
				sal_subledger_docno,
				sal_ref2,
				sal_dept_docno,
				sal_bill_mobile,
				sal_delivery_date,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_deltrm_docno,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_paytrm_docno,
				sal_divn_docno,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_ud_label1,
				sal_ud_label4,
				sal_ud_label3,
				sal_ud_label2,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				sal_vat_treatment,
				sal_posted_by,
				sal_posted_ts ,
				--sal_cont_start_date,
				sal_cont_end_date,
				sal_comments1,
				--sal_service_type_docno,
			
				--sal_rebate_yn,
				--sal_trms_docno,
				sal_sman_desc,
				sal_ud_label9,
				sal_ud_label10,
				sal_order_amount,
				sal_retention_percent,
				sal_retention_amount,
				sal_adv_recovery_percent,
				sal_adv_recovery_amount,
				sal_invoice_amount,
				sal_total_amount,
				sal_net_amount
		FROM	#DetailTable
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno	
		--INNER JOIN sales_details sd ON 
		--		#DetailTable.saldet_fycode		= sd.saldet_fycode  AND
		--		#DetailTable.saldet_doctype		= sd.saldet_doctype  AND
		--		#DetailTable.saldet_docno		= sd.saldet_docno	AND
		--		#DetailTable.saldet_docsrno		= sd.saldet_docsrno	
		--INNER JOIN stock_master ON
		--		stkmst_docno	= #DetailTable.SALDET_STOCK_DOCNO	
 	--	INNER JOIN stock_location_master ON
		--		stkloc_doctype = #DetailTable.saldet_stock_doctype AND
		--		stkloc_docno   = #DetailTable.saldet_stock_docno AND
		--		stkloc_loc_docno = #DetailTable.saldet_location_docno		
		ORDER by	saldet_docsrno
		END

	IF @strDocType IN('SI10','SI20','SI30','SI40','SI50','SI60') and @strPrevDocType like 'SO%'
	BEGIN 
	PRINT 'Sales invoice'
		SET @strSQLString = N'INSERT INTo #DetailTable5
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					CASE WHEN '''+@strDocType+''' =''SI'' then SALDET_LOCATION_DOCNO else
					ISNULL(NULLIF(SALDET_LOCATION_DOCNO,''''),''' + ISNULL(@strDefaultLocation,'') + ''') end AS SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO	,
					JOBMST_BUDJ_INCOME
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype		=  '''+@strjobdocno+'''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					ISNULL(sal_document_status_docno,''ACT'') not in (''VOID'',''1002'') AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable5
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable5.*,
				#DetailTable5.saldet_fycode	AS [Fycode],
				#DetailTable5.saldet_doctype	AS [DocType],
				#DetailTable5.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno	,
				SAL_ROUNDOFF_AMOUNT,
				SAL_RETNTION_VAT_ADJUSTMENT,
				SAL_RETENTION_PERCENT,
				SAL_RETENTION_AMOUNT
		FROM	#DetailTable5	 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END
	IF @strDocType LIKE  'PCC%'  
	BEGIN
	--PRINT 'HERE'
	SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT	jobmst_fycode,	
					jobmst_doctype	,
					jobmst_docno,	
					 jobtrn_docsrno,
					  
					''' + @strDefaultLineItemType +'''						AS SALDET_STOCK_DOCTYPE,
					''10000''												AS SALDET_STOCK_DOCNO,		
					jobtrn_stock_desc										AS SALDET_STOCK_DESC,
					''' + @strDefaultLocation1 +'''							AS SALDET_LOCATION_DOCNO,
					1														AS SALDET_QTY,
					 ''LS'' 												AS SALDET_UNIT_DOCNO, 
					0.00													AS SALDET_RATE,
					0.00													AS SALDET_AMOUNT,
					0.00													AS SALDET_GROSS_AMOUNT,
					0														AS SALDET_DISCOUNT_AMOUNT,
					0														AS SALDET_DISCOUNT_PERCENT,
					JOBTRN_DOCTYPE											AS SALDET_CAT_REF,
					jobmst_sch_startdate									AS SALDET_DOCDATE,
					NULL AS SALDET_EXTENDED_DESC,	
					NULL AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00,
					JOBTRN_FYCODE											AS SALDET_PREVIOUS_FYCODE,
					JOBTRN_DOCTYPE											AS SALDET_PREVIOUS_DOCTYPE,
					JOBTRN_DOCNO											AS SALDET_PREVIOUS_DOCNO,
					JOBTRN_DOCSRNO											AS SALDET_PREVIOUS_DOCSRNO,
					0														AS SALDET_AFTER_DOC_QTY,
					0														AS AFTERDOCQTY,
					0														AS RESERVEDQTY,
					0														AS BEFOREQTY,
					ACMST_DESC,
					NULL AS SUBLMST_DESC,
					acmst_divn_docno										AS FIXED_DIVISION,
					JOBMST_REFNO											AS SALDET_REFONENUMBER,
					JOBMST_REFDATE											AS SALDET_REFONEDATE,
					NUll													AS SALDET_REFTWODATE,
					''' +@strDivisionDocNo + '''							AS SALDET_DIVN_DOCNO,
					divn_desc												AS SALDET_DIVN_DESC,
					JOBMST_DEPT_DOCNO										AS SALDET_DEPT_DOCNO,
					DEPT_DESC												AS SALDET_DEPT_DESC,
					Null													AS DOCSTAUS,'
	SET @strSQLString = @strSQLString + '
					JOBMST_SMAN_DOCNO										AS SALDET_SMAN_DOCNO,
					SMAN_DESC												AS SALDET_SMAN_DESC,
					NULL													AS SALDET_LOC_DESC,
					JOBMST_DOCNO											AS SALDET_JOB_DOCNO,
					jobmst_desc												AS SALDET_JOBMST_DESC,
					acmst_curr_docno										AS SALDET_CURR_DOCNO,
					NULL													AS SALDET_SUBLEDGER_DOCNO,					
					--acmst_DEsc,
					--PARTYMST_DESC AS sublmst_Desc,
					5		AS saldet_vat_percentage,
					''SR''	AS saldet_vat_category_docno,
					0	AS SALDET_CONTRACT_VALUE	,
					NULL,
					0																	AS SALDET_CUR_CUM_INV_PER,	
					0																	AS SALDET_CUR_CUM_INV_AMT,	
					PreviousCumulativeInvPerc											AS SALDET_PRE_CUM_INV_PER,	
					PreviousCumulativeInvAmount											AS SALDET_PRE_CUM_INV_AMT,
					NULL																AS SALDET_INVOICE_PERCENT,	
					NULL																AS SALDET_WORKCOMPLETION_PERCENT,	
					null																AS	SALDET_GROUP_HEADEING1	,
					null																AS	SALDET_GROUP_HEADEING2	,
					ABS(ISNULL(jobtrn_qty,1))											AS SALDET_BUDGET_QTY,
					ABS(ISNULL(jobtrn_rate,0))											AS SALDET_RATE,
					ABS(ISNULL(jobtrn_amount,0))										AS SALDET_AMOUNT,
					jobtrn_cost_docno
		FROM	job_master
		INNER JOIN	job_transaction ON
				jobtrn_job_docno = jobmst_docno
		INNER JOIN division_master ON
				divn_docno	=	jobmst_divn_docno
		LEFT JOIN department_master ON
				dept_docno	=	jobmst_dept_docno
		LEFT JOIN salesman_master ON
				jobmst_sman_docno = sman_docno
		LEFT JOIN vw_accountmaster_report on
				acmst_docno = jobmst_ac_docno AND
				acmst_subledger_docno = ISNULL( jobmst_subledger_docno, jobmst_ac_docno)
		OUTER APPLY 
			(
					SELECT
							SUM(jobtrn_percentage)	as PreviousCumulativeInvPerc,	
							SUM(jobtrn_amount)		as PreviousCumulativeInvAmount
					FROM	job_transaction uu
					INNER JOIN sales_details ON
							saldet_fycode	=	jobtrn_fycode	AND
							saldet_doctype	=	jobtrn_doctype	AND
							saldet_docno	=	jobtrn_docno	AND
							saldet_docsrno	=	jobtrn_docsrno
					WHERE	uu.jobtrn_job_docno		=	job_master.jobmst_docno and
							uu.jobtrn_cost_docno	=	job_transaction.jobtrn_cost_docno
							
			)xyz
		WHERE (JOBTRN_DOCTYPE  LIKE  ''BOEXV%'' OR JOBTRN_DOCTYPE  LIKE  ''BOQVA%'') AND
				jobmst_divn_docno = '''+@strDivisionDocNo+''''

		PRINT CAST(@strSQLString as ntext)
		EXEC(@strSQLString  ) 
 

		INSERT #Tmp_Table1
		(
				tmp_FyCode,
				tmp_DocType,
				tmp_docno,
				tmp_docdate,
						
				tmp_party,
				tmp_description,
						
				tmp_RefOneNumber	,
				tmp_RefOneDate		,
				tmp_RefTwoNumber	,					
				tmp_RefTwoDate		,
						
				tmp_Location		,
				tmp_SalesMan		,
				tmp_division		,
				tmp_department		,
				tmp_currency		,
				tmp_jobCode			,
				tmp_jobDesc	
						 
		)

		SELECT	
				jobmst_fycode		AS FyCode,
				jobmst_doctype		AS DocType,
				jobmst_docno		AS DocNo, 
				jobmst_docdate		AS Date,
				CASE WHEN jobmst_ac_docno = jobmst_subledger_docno THEN jobmst_ac_docno 
				ELSE jobmst_ac_docno + '-'+jobmst_subledger_docno END AS pur_ac_docno,
				acmst_desc			AS Party,	
				NULL,
				NULL,
				NULL,
				null,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				jobmst_docno	AS JobNo,
				jobmst_desc		AS JobDescription
		FROM	job_master 
		LEFT JOIN vw_accountmaster_report on
				acmst_docno = jobmst_ac_docno AND
				acmst_subledger_docno = ISNULL( jobmst_subledger_docno, jobmst_ac_docno)
		WHERE	jobmst_divn_docno = @strDivisionDocNo

							
		SELECT	tmp_docno			AS DocNo,
				tmp_DocType			AS DocType,
				tmp_docdate			AS Date,
				tmp_party			AS PartyCode,
				tmp_description		AS Party,				 
				tmp_FyCode			AS FyCode,
				tmp_RefOneNumber	AS [RefOneNumber],
				tmp_RefOneDate		AS [RefOneDate],
				tmp_RefTwoNumber	AS RefTwoNumber,	
				tmp_RefTwoDate		AS RefTwoDate	,	
				tmp_Location		AS Location	,	
				tmp_SalesMan		AS SalesMan	,	
				tmp_division		AS	Division	,	
				tmp_department		AS	Department	,	
				tmp_currency		AS	Currency,	
				0					AS [Amount],
				tmp_jobCode			AS JobNo			,
				tmp_jobDesc			AS JobDescription
		FROM	#Tmp_Table1
		ORDER BY tmp_docdate DESC


		SELECT 
			tmp_FyCode				AS	FYCODE,
			tmp_DocType				AS	DOCTYPE,
			tmp_docno				AS	DOCNO,
			JOBMST_DOCDATE			AS	[DocDate],
			JOBMST_DOCNO			AS	SALDET_PREVIOUS_DOCNO,
			JOBMST_DOCTYPE			AS	SALDET_PREVIOUS_DOCTYPE,
			JOBMST_FYCODE			AS  SALDET_PREVIOUS_FYCODE,
			
			JOBMST_DOCNO			AS	SAL_PREVIOUS_DOCNO,
			JOBMST_DOCTYPE			AS	SAL_PREVIOUS_DOCTYPE,
			JOBMST_FYCODE			AS  SAL_PREVIOUS_FYCODE,
			@stracdocno				AS 	SAL_AC_DOCNO,
			JOBMST_SUBLEDGER_DOCNO	AS	SAL_SUBLEDGER_DOCNO,
			JOBMST_DOCNO			AS	SAL_JOB_DOCNO,
			0.00					AS	SAL_ORDER_AMOUNT,
			*
		FROM	#DetailTable
		INNER JOIN JOB_MASTER ON 
				jobmst_fycode	= saldet_fycode  AND
				jobmst_doctype	= saldet_doctype  AND
				jobmst_docno	= saldet_docno
		INNER JOIN #Tmp_Table1 ON
				tmp_jobCode = saldet_job_docno

	/*
		INSERT #Tmp_Table1
		(
				tmp_FyCode,
				tmp_DocType,
				tmp_docno,
				tmp_docdate,
						
				tmp_party,
				tmp_description,
						
				tmp_RefOneNumber	,
				tmp_RefOneDate		,
				tmp_RefTwoNumber	,					
				tmp_RefTwoDate		,
						
				tmp_Location		,
				tmp_SalesMan		,
				tmp_division		,
				tmp_department		,
				tmp_currency		,
				tmp_jobCode			,
				tmp_jobDesc	
						 
		)
		SELECT	
				jobmst_fycode,
				jobmst_doctype,
				jobmst_docno, 
				jobmst_docdate,
				CASE WHEN jobmst_ac_docno = jobmst_subledger_docno THEN jobmst_ac_docno 
				ELSE jobmst_ac_docno + '-'+jobmst_subledger_docno END AS pur_ac_docno,
				acmst_desc,	
				NULL,
				NULL,
				NULL,
				null,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				jobmst_desc
		FROM	job_master 
		LEFT JOIN vw_accountmaster_report on
				acmst_docno = jobmst_ac_docno AND
				acmst_subledger_docno = ISNULL( jobmst_subledger_docno, jobmst_ac_docno)
		WHERE	jobmst_divn_docno = @strDivisionDocNo
		--WHERE	pur_fycode	= @strFyCode AND
		--		pur_doctype = @strPrevDocType AND 
		--		pur_docdate >= @dtFmdate AND
		--		pur_docdate < @dtTodate AND
		--		pur_ac_docno = ISNULL( @strACCode, pur_ac_docno) AND
		--		ISNULL( pur_subledger_docno, pur_ac_docno) = ISNULL( @strSubledgerCode, ISNULL( pur_subledger_docno,pur_ac_docno)) AND			
		--		pur_docno = ISNULL( @strPrevDocNo, pur_docno) AND
		--		pur_revised_docno	IS	NULL 						
								
		SELECT	tmp_docno			AS DocNo,
				tmp_DocType			AS DocType,
				tmp_docdate			AS Date,
				tmp_party			AS PartyCode,
				tmp_description		AS Party,				 
				tmp_FyCode			AS FyCode,
				tmp_RefOneNumber	AS [RefOneNumber],
				tmp_RefOneDate		AS [RefOneDate],
				tmp_RefTwoNumber	AS RefTwoNumber,	
				tmp_RefTwoDate		AS RefTwoDate	,	
				tmp_Location		AS Location	,	
				tmp_SalesMan		AS SalesMan	,	
				tmp_division		AS	Division	,	
				tmp_department		AS	Department	,	
				tmp_currency		AS	Currency,	
				0					AS [Amount],
				tmp_jobCode			AS JobNo			,
				tmp_jobDesc			AS JobDescription
		FROM	#Tmp_Table1
		ORDER BY tmp_docdate DESC
		
		
			
	
		
	
		SELECT	tmp_fycode				    AS [Fycode],
				tmp_doctype				    AS [DocType],
				tmp_docno				    AS [DocNo],
				tmp_docdate				    AS [DocDate],
						
				jobtrn_stock_docno  		AS [Stock Code],
				jobtrn_stock_desc   		AS [Stock Desc]  ,
				jobtrn_qty					AS Qty,
				jobtrn_rate					AS [Rate],
				jobtrn_amount				AS [Amount],
											
				jobtrn_docno				AS  SALDET_DOCNO, 
				jobtrn_docsrno				AS  SALDET_DOCSRNO, 
				'JOB'						AS  SALDET_STOCK_DOCTYPE, 
				jobtrn_stock_docno			AS  SALDET_STOCK_DOCNO, 
				jobtrn_stock_desc			AS	SALDET_STOCK_DESC, 
				@strDefaultLocation			AS  SALDET_LOCATION_DOCNO, 
				jobtrn_qty					AS  SALDET_QTY, 
				'LS'						AS	SALDET_UNIT_DOCNO, 
				jobtrn_rate					AS 	SALDET_RATE, 
				jobtrn_amount				AS	SALDET_AMOUNT, 
				jobtrn_amount				AS  SALDET_GROSS_AMOUNT, 
				0.00						AS 	SALDET_DISCOUNT_AMOUNT, 
				0.00						AS 	SALDET_DISCOUNT_PERCENT, 					
				jobtrn_fycode				AS 	SALDET_PREVIOUS_FYCODE, 
				jobtrn_doctype				AS 	SALDET_PREVIOUS_DOCTYPE, 
				jobtrn_docno				AS 	SALDET_PREVIOUS_DOCNO, 
				jobtrn_docsrno				AS 	SALDET_PREVIOUS_DOCSRNO, 
				0							AS 	SALDET_AFTER_DOC_QTY, 			
				GETDATE()					AS 	SALDET_DOCDATE, 			
				NULL						AS 	SALDET_EXTENDED_DESC, 
				jobtrn_fycode				AS 	SALDET_BEFORE_FYCODE, 
				jobtrn_doctype				AS 	SALDET_BEFORE_DOCTYPE, 
				jobtrn_docno				AS 	SALDET_BEFORE_DOCNO, 
				jobtrn_docsrno				AS 	SALDET_BEFORE_DOCSRNO, 
				NULL						AS 	SALDET_REMARKS, 
				NULL						AS  SALDET_ITEM_NO,
				NULL						AS	MATRIX_STRING,
				NULL						as	PUR_BID_DUE_DATE,
				NULL						as	SALDET_CUSTOMER_REFNO,
				NULL						AS	SALDET_CUSTOMER_REFDESC,
				NULL						AS 	SALDET_CAT_REF,
						
				NULL						AS  SAL_AC_DOCNO,
				NULL						AS  SAL_SUBLEDGER_DOCNO,
				NULL						AS  SUBLMST_DESC,
				NULL						AS  SAL_BILL_CONTACT_DOCNO,
				NULL						AS  SAL_BILL_CONTACT_NAME,
				500000						AS	BEFOREQTY						
		FROM	#Tmp_Table1
		INNER JOIN	job_transaction ON
				jobtrn_job_docno = tmp_docno
		WHERE (JOBTRN_DOCTYPE  LIKE  'BOEXV%' OR JOBTRN_DOCTYPE  LIKE  'BOQVA%')
		*/

	


	/*
		SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT	 IBOQEDET_FYCODE,
					 IBOQEDET_DOCTYPE,
					 IBOQEDET_DOCNO,
					 IBOQEDET_DOCSRNO,
					  
					''' + @strDefaultLineItemType +'''						as SALDET_STOCK_DOCTYPE,
					''10000''												as SALDET_STOCK_DOCNO,		
					IBOQEDET_LINE_ITEM_DESC									as SALDET_STOCK_DESC,
					''' + @strDefaultLocation1 +'''							as SALDET_LOCATION_DOCNO,
					1									AS SALDET_QTY,
					 ''LS'' 												AS SALDET_UNIT_DOCNO, 
					0														AS SALDET_RATE,
					0														AS SALDET_AMOUNT,
					0														AS SALDET_GROSS_AMOUNT,
					0														AS SALDET_DISCOUNT_AMOUNT,
					0														AS SALDET_DISCOUNT_PERCENT,
					NULL													AS SALDET_CAT_REF,
					jobmst_sch_startdate									AS SALDET_DOCDATE,
					NULL AS SALDET_EXTENDED_DESC,	
					NULL AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00,
					IBOQEDET_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					IBOQEDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					IBOQEDET_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					IBOQEDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					0												AS BEFOREQTY,
					ACMST_DESC,
					NULL AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,
					JOBMST_REFNO									AS SALDET_REFONENUMBER,
					JOBMST_REFDATE									AS SALDET_REFONEDATE,
					NUll											AS SALDET_REFTWODATE,
					''' +@strDivisionDocNo + '''					AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					JOBMST_DEPT_DOCNO								AS SALDET_DEPT_DOCNO,
					DEPT_DESC										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,'
	SET @strSQLString = @strSQLString + '
					JOBMST_SMAN_DOCNO								AS SALDET_SMAN_DOCNO,
					SMAN_DESC										AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					JOBMST_DOCNO									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					acmst_curr_docno									AS SALDET_CURR_DOCNO,
					NULL								AS SALDET_SUBLEDGER_DOCNO,					
					--acmst_DEsc,
					--PARTYMST_DESC AS sublmst_Desc,
					5		AS saldet_vat_percentage,
					''SR''	AS saldet_vat_category_docno,
					0	AS SALDET_CONTRACT_VALUE	,
					NULL,
					0																	AS SALDET_CUR_CUM_INV_PER,	
					0																	AS SALDET_CUR_CUM_INV_AMT,	
					PreviousCumulativeInvPerc											AS SALDET_PRE_CUM_INV_PER,	
					PreviousCumulativeInvAmount											AS SALDET_PRE_CUM_INV_AMT,
					NULL																AS SALDET_INVOICE_PERCENT,	
					NULL																AS SALDET_WORKCOMPLETION_PERCENT,	
					iboqedet_level_2													AS	SALDET_GROUP_HEADEING1	,
					iboqedet_level_3													AS	SALDET_GROUP_HEADEING2	,
					isnull(IBOQEDET_QTY,1)												AS SALDET_BUDGET_QTY,
					isnull(IBOQEDET_RATE,0)												AS SALDET_RATE,
					isnull(IBOQEDET_AMOUNT,0)											AS SALDET_AMOUNT,
					iboqedet_cost_code
					
			FROM	iboqe_details 
			INNER JOIN DATA_FROM_EXTERNAL_SOURCE_HEADER ON
					IBOQEDET_FYCODE			=	DFES_FYCODE AND
					IBOQEDET_doctype		=	DFES_doctype AND 
					IBOQEDET_docno			=	DFES_docno 
			INNER JOIN job_master ON
			     DFES_JOB_DOCNO   = jobmst_docno
			LEFT OUTER JOIN account_master ON
				acmst_docno = jobmst_ac_docno
			LEFT OUTER JOIN party_master ON
					partymst_doctype = jobmst_ac_docno and
					partymst_docno = isnull(jobmst_subledger_docno,jobmst_ac_docno) 	
			LEFT JOIN division_master Div  ON
					jobmst_divn_docno = Div.divn_docno
			LEFT JOIN department_master dept  ON
				jobmst_dept_docno = dept.dept_docno
			LEFT JOIN salesman_master sman  ON
				jobmst_sman_docno = sman.sman_docno 
			OUTER APPLY 
			(
					SELECT
							SUM(jobtrn_percentage)	as PreviousCumulativeInvPerc,	
							SUM(jobtrn_amount)		as PreviousCumulativeInvAmount
					FROM	job_transaction
					INNER JOIN sales_details ON
							saldet_fycode	=	jobtrn_fycode	AND
							saldet_doctype	=	jobtrn_doctype	AND
							saldet_docno	=	jobtrn_docno	AND
							saldet_docsrno	=	jobtrn_docsrno
					WHERE	jobtrn_job_docno	=	jobmst_docno and
							jobtrn_cost_docno	=	iboqedet_cost_code
							
			)xyz
			WHERE	jobmst_fycode			= ''' + @strFyCode + ''' AND
					--jobmst_sch_startdate			>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					--jobmst_sch_startdate			< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					--jobmst_job_status_docno	<>	''CLOSED''		AND
					IBOQEDET_ROW_IDENTIFIER =''BOQ_Line_Item'' AND
					##PREVDOCTYPE##
					
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					1 = 1'


		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' iboqedet_doctype  = ('''+ @strPrevDocType + ''')  AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' jobmst_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' jobmst_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' jobmst_docno ='''+ @strPrevDocNo + ''' AND ' )

		SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' dfes_posted_by is not null AND ' )

		--INSERT INTO USP_SQL_STRING 
		--SELECT @strSQLString, NEWID() ,GETDATE()

		PRINt CAST(@strSQLString AS NTEXT)
		EXEC(@strSQLString  )
	
		SELECT	saldet_docno						AS DocNo,
				saldet_doctype						AS DocType,
				MAX( saldet_docdate)					AS Date,
				NULL									AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode					AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 			#DetailTable.*,
						DFES_FYCODE				as [Fycode],
						DFES_DOCTYPE			as [DocType],
						DFES_DOCNO				as [DocNo],
						DFES_DOCDATE			as [DocDate] ,
						JOBMST_SUBLEDGER_DOCNO	AS sal_subledger_docno,
						CASE 
						when @strDocType = 'PCC10' THEN 'AR10'
						when @strDocType = 'PCC20' THEN 'AR20'
						when @strDocType = 'PCC30' THEN 'AR30'
						when @strDocType = 'PCC40' THEN 'AR40'
						when @strDocType = 'PCC50' THEN 'AR50'
						when @strDocType = 'PCC60' THEN 'AR60' 
						ELSE NULL END			AS sal_ac_docno,
						DFES_JOB_DOCNO			AS sal_job_docno ,
						'AED'					AS sal_curr_docno,
						1						AS sal_curr_rate,
						'SR'					AS saldet_vat_category_docno,
						'SR'					AS saldet_vat_docno,
						5						AS saldet_vat_percentage
		FROM	#DetailTable 
		INNER JOIN data_from_external_source_header ON
				saldet_fycode			=	dfes_fycode		AND
				saldet_doctype			=	dfes_doctype AND 
				saldet_docno			=	dfes_docno  
			INNER JOIN job_master ON
			     dfes_job_docno   = jobmst_docno
		LEFT OUTER JOIN vw_accountmaster_report ON
			acmst_docno			=	jobmst_ac_docno AND
			acmst_subledger_docno	=	ISNULL( jobmst_subledger_docno,jobmst_ac_docno)
		LEFT JOIN currency_master ON
			curr_docno =  acmst_curr_docno
		INNER JOIN document_master ON
			dm_docno = saldet_doctype						
		ORDER BY	saldet_docsrno
*/

	END

	IF @strPrevDocType LIKE  'BOQVA%' --and @strHeaderTable = 'JOB_MASTER'
	BEGIN
	--PRINT 'HERE'
		SET @strSQLString = N'INSERT INTo #DetailTable
			SELECT	 IBOQEDET_FYCODE,
					 IBOQEDET_DOCTYPE,
					 IBOQEDET_DOCNO,
					 IBOQEDET_DOCSRNO,
					  
					''BOQ''												as SALDET_STOCK_DOCTYPE,
					''20000''												as SALDET_STOCK_DOCNO,		
					IBOQEDET_LINE_ITEM_DESC									as SALDET_STOCK_DESC,
					''' + @strDefaultLocation1 +'''							as SALDET_LOCATION_DOCNO,
					1									AS SALDET_QTY,
					 ''LS'' 												AS SALDET_UNIT_DOCNO, 
					0														AS SALDET_RATE,
					0														AS SALDET_AMOUNT,
					0														AS SALDET_GROSS_AMOUNT,
					0														AS SALDET_DISCOUNT_AMOUNT,
					0														AS SALDET_DISCOUNT_PERCENT,
					NULL													AS SALDET_CAT_REF,
					jobmst_sch_startdate									AS SALDET_DOCDATE,
					NULL AS SALDET_EXTENDED_DESC,	
					NULL AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00,
					IBOQEDET_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					IBOQEDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					IBOQEDET_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					IBOQEDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					0												AS BEFOREQTY,
					ACMST_DESC,
					NULL AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,
					JOBMST_REFNO									AS SALDET_REFONENUMBER,
					JOBMST_REFDATE									AS SALDET_REFONEDATE,
					NUll											AS SALDET_REFTWODATE,
					''' +@strDivisionDocNo + '''					AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					JOBMST_DEPT_DOCNO								AS SALDET_DEPT_DOCNO,
					DEPT_DESC										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,'
	SET @strSQLString = @strSQLString + '
					JOBMST_SMAN_DOCNO								AS SALDET_SMAN_DOCNO,
					SMAN_DESC										AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					JOBMST_DOCNO									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					acmst_curr_docno									AS SALDET_CURR_DOCNO,
					NULL								AS SALDET_SUBLEDGER_DOCNO,					
					--acmst_DEsc,
					--PARTYMST_DESC AS sublmst_Desc,
					5		AS saldet_vat_percentage,
					''SR''	AS saldet_vat_category_docno,
					0	AS SALDET_CONTRACT_VALUE	,
					NULL,
					0																	AS SALDET_CUR_CUM_INV_PER,	
					0																	AS SALDET_CUR_CUM_INV_AMT,	
					ISNULL(PreviousCumulativeInvPerc,0)									AS SALDET_PRE_CUM_INV_PER,	
					ISNULL(PreviousCumulativeInvAmount,0)								AS SALDET_PRE_CUM_INV_AMT,
					NULL																AS SALDET_INVOICE_PERCENT,	
					NULL																AS SALDET_WORKCOMPLETION_PERCENT,	
					iboqedet_level_2													AS	SALDET_GROUP_HEADEING1	,
					iboqedet_level_3													AS	SALDET_GROUP_HEADEING2	,
					isnull(IBOQEDET_QTY,1)												AS SALDET_BUDGET_QTY,
					isnull(IBOQEDET_RATE,0)												AS SALDET_RATE,
					isnull(IBOQEDET_AMOUNT,0)											AS SALDET_AMOUNT,
					iboqedet_cost_code
					
			FROM	iboqe_details 
			INNER JOIN DATA_FROM_EXTERNAL_SOURCE_HEADER ON
					IBOQEDET_FYCODE			=	DFES_FYCODE AND
					IBOQEDET_doctype		=	DFES_doctype AND 
					IBOQEDET_docno			=	DFES_docno 
			INNER JOIN job_master ON
			     DFES_JOB_DOCNO   = jobmst_docno
			LEFT OUTER JOIN account_master ON
				acmst_docno = jobmst_ac_docno
			LEFT OUTER JOIN party_master ON
					partymst_doctype = jobmst_ac_docno and
					partymst_docno = isnull(jobmst_subledger_docno,jobmst_ac_docno) 	
			LEFT JOIN division_master Div  ON
					jobmst_divn_docno = Div.divn_docno
			LEFT JOIN department_master dept  ON
				jobmst_dept_docno = dept.dept_docno
			LEFT JOIN salesman_master sman  ON
				jobmst_sman_docno = sman.sman_docno 
			OUTER APPLY 
			(
					SELECT
							SUM(jobtrn_percentage)	as PreviousCumulativeInvPerc,	
							SUM(jobtrn_amount)		as PreviousCumulativeInvAmount
					FROM	job_transaction
					INNER JOIN sales_details ON
							saldet_fycode	=	jobtrn_fycode	AND
							saldet_doctype	=	jobtrn_doctype	AND
							saldet_docno	=	jobtrn_docno	AND
							saldet_docsrno	=	jobtrn_docsrno
					WHERE	jobtrn_job_docno	=	jobmst_docno and
							jobtrn_cost_docno	=	iboqedet_cost_code
							
			)xyz
			WHERE	jobmst_fycode			= ''' + @strFyCode + ''' AND
					--jobmst_sch_startdate			>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					--jobmst_sch_startdate			< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					--jobmst_job_status_docno	<>	''CLOSED''		AND
					IBOQEDET_ROW_IDENTIFIER =''BOQ_Line_Item'' AND
					##PREVDOCTYPE##
					
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					1 = 1'


		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' iboqedet_doctype  = ('''+ @strPrevDocType + ''')  AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' jobmst_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' jobmst_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' jobmst_docno ='''+ @strPrevDocNo + ''' AND ' )

		SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' dfes_posted_by is not null AND ' )

		--INSERT INTO USP_SQL_STRING 
		--SELECT @strSQLString, NEWID() ,GETDATE()

		PRINt CAST(@strSQLString AS NTEXT)
		EXEC(@strSQLString  )
	
		SELECT	saldet_docno						AS DocNo,
				saldet_doctype						AS DocType,
				MAX( saldet_docdate)					AS Date,
				NULL									AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode					AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 			#DetailTable.*,
						DFES_FYCODE				as [Fycode],
						DFES_DOCTYPE			as [DocType],
						DFES_DOCNO				as [DocNo],
						DFES_DOCDATE			as [DocDate] ,
						JOBMST_SUBLEDGER_DOCNO	AS sal_subledger_docno,
						NULL					AS sal_ac_docno,
						DFES_JOB_DOCNO			AS sal_job_docno ,
						'AED'					AS sal_curr_docno,
						1						AS sal_curr_rate,
						'SR'					AS saldet_vat_category_docno,
						'SR'					AS saldet_vat_docno,
						5						AS saldet_vat_percentage
		FROM	#DetailTable 
		INNER JOIN data_from_external_source_header ON
				saldet_fycode			=	dfes_fycode		AND
				saldet_doctype			=	dfes_doctype AND 
				saldet_docno			=	dfes_docno  
			INNER JOIN job_master ON
			     dfes_job_docno   = jobmst_docno
		LEFT OUTER JOIN vw_accountmaster_report ON
			acmst_docno			=	jobmst_ac_docno AND
			acmst_subledger_docno	=	ISNULL( jobmst_subledger_docno,jobmst_ac_docno)
		LEFT JOIN currency_master ON
			curr_docno =  acmst_curr_docno
		INNER JOIN document_master ON
			dm_docno = saldet_doctype						
		ORDER BY	saldet_docsrno
	END
	
	IF @strDocType = 'SVPA60' and @strDocType not like 'SI%'
	BEGIN
		SET @strSQLString = N'INSERT INTo #DetailTable4
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					CASE WHEN '''+@strDocType+''' =''SI'' then SALDET_LOCATION_DOCNO else
					ISNULL(NULLIF(SALDET_LOCATION_DOCNO,''''),''' + ISNULL(@strDefaultLocation,'') + ''') end AS SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE,
					SALDET_VAT_CATEGORY_DOCNO		,
					SALDET_CONTRACT_VALUE
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					ISNULL(NULLIF(sal_document_status_docno,''''),''ACT'') = ''ACT'' AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable4
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable4.*,
				#detailtable4.saldet_fycode	AS [Fycode],
				#detailtable4.saldet_doctype	AS [DocType],
				#detailtable4.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno	,
				SAL_ROUNDOFF_AMOUNT,
				SAL_RETNTION_VAT_ADJUSTMENT,
				SAL_RETENTION_PERCENT,
				SAL_RETENTION_AMOUNT
		FROM	#DetailTable4
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END

	IF @strDocType IN('SVIS60','AVIS60') and @strPrevDocType IN('SVQS60','ASQS60')
	BEGIN
	--raiserror('here',16,1)
	PRINT 'Sales invoice'
		SET @strSQLString = N'INSERT INTo #DetailTable5
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					''1'',--SALDET_DOCSRNO,
					MAX(SALDET_STOCK_DOCTYPE),
					MAX(SALDET_STOCK_DOCNO),		
					MAX(SALDET_STOCK_DESC),
					CASE WHEN '''+@strDocType+''' =''SI'' then MAX(SALDET_LOCATION_DOCNO) else
					ISNULL(NULLIF(MAX(SALDET_LOCATION_DOCNO),''''),''' + ISNULL(@strDefaultLocation,'') + ''') end AS SALDET_LOCATION_DOCNO,
					''1'' AS SALDET_QTY,--(MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) SALDET_QTY,
					''LS'' AS SALDET_UNIT_DOCNO,--MAX(SALDET_UNIT_DOCNO),
					MAX(JOBMST_BUDJ_INCOME) AS SALDET_RATE,--MAX(SALDET_RATE),
					0.00,--((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE)) - ((((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE))* MAX(SALDET_DISCOUNT_PERCENT))/100)  AS SALDET_AMOUNT,
					0.00,--(MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE) AS SALDET_GROSS_AMOUNT,
					0.00,--(((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE))* MAX(SALDET_DISCOUNT_PERCENT))/100 AS SALDET_DISCOUNT_AMOUNT,
					0.00,--MAX(SALDET_DISCOUNT_PERCENT),
					MAX(SALDET_CAT_REF),
					MAX(SALDET_DOCDATE),
					MAX(SALDET_EXTENDED_DESC),
					MAX(SALDET_REMARKS),
					MAX(SALDET_CUSTOMER_REFDESC),
					MAX(SALDET_BATCH_DOCNO),
					MAX(SALDET_OTHER_AMOUNT),
					MAX(SALDET_FYCODE)									AS SALDET_PREVIOUS_FYCODE,
					MAX(SALDET_DOCTYPE)									AS SALDET_PREVIOUS_DOCTYPE,
					MAX(SALDET_DOCNO)									AS SALDET_PREVIOUS_DOCNO,
					MAX(SALDET_DOCSRNO)									AS SALDET_PREVIOUS_DOCSRNO,
					0													AS SALDET_AFTER_DOC_QTY,
					0													AS AFTERDOCQTY,
					0													AS RESERVEDQTY,
					MAX(SALDET_QTY) - ISNULL( MAX(SALDET_AFTER_DOC_QTY),0)	AS BEFOREQTY,
					MAX(acmst_desc)										AS ACMST_DESC,
					MAX(SUBLMST_DESC)									AS SUBLMST_DESC,
					MAX(acmst_divn_docno)								AS FIXED_DIVISION,

					MAX(sal_refno)										AS SALDET_REFONENUMBER,
					MAX(sal_refdate)									AS SALDET_REFONEDATE,
					--sal_ref2											AS SALDET_REFTWONUMBER,
					NUll												AS SALDET_REFTWODATE,
					MAX(sal_divn_docno)									AS SALDET_DIVN_DOCNO,
					MAX(divn_desc)										AS SALDET_DIVN_DESC,
					MAX(sal_dept_docno)									AS SALDET_DEPT_DOCNO,
					MAX(dept_desc)										AS SALDET_DEPT_DESC,
					Null												AS DOCSTAUS,
					MAX(sal_sman_docno)									AS SALDET_SMAN_DOCNO,
					MAX(sman_Desc)										AS SALDET_SMAN_DESC,
					MAX(location_master.loc_desc)						AS SALDET_LOC_DESC,
					MAX(sal_job_docno)									AS SALDET_JOB_DOCNO,
					MAX(jobmst_desc)									AS SALDET_JOBMST_DESC,
					MAX(sal_curr_docno)									AS SALDET_CURR_DOCNO,
					MAX(sal_subledger_docno)							AS SALDET_SUBLEDGER_DOCNO,					
					MAX(SALDET_VAT_PERCENTAGE),
					MAX(SALDET_VAT_CATEGORY_DOCNO)	,
					MAX(JOBMST_BUDJ_INCOME)						
			FROM	SALES_DETAILS' 
	SET @strSQLString = @strSQLString+	' INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master   on
					jobmst_docno		=  sal_job_docno 
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					ISNULL(sal_document_status_docno,'''') <> ''CLOSED'' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
			GROUP BY SALDET_FYCODE,SALDET_DOCTYPE,SALDET_DOCNO '

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null  ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		--SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable5
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable5.*,
				#detailtable5.saldet_fycode	AS [Fycode],
				#detailtable5.saldet_doctype	AS [DocType],
				#detailtable5.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				'SJOB' AS sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				0 AS sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno	,
				SAL_ROUNDOFF_AMOUNT,
				SAL_RETNTION_VAT_ADJUSTMENT,
				SAL_RETENTION_PERCENT,
				SAL_RETENTION_AMOUNT
		FROM	#DetailTable5
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END

	IF @strDocType = 'SVIS60'  and @strPrevDocType = 'SCCA60'
	BEGIN
		SET @strSQLString = N'INSERT INTo #DetailTable4
		SELECT			
					SC_FYCODE,
					SC_DOCTYPE,
					SC_DOCNO,
					SCBDET_DOCSRNO,
					''SMNS'',
					''101'',		
					ISNULL(NULLIF(SCBDET_DESC,''''),''NON STOCK ITEM''),
					''31''AS SALDET_LOCATION_DOCNO,
					1 AS SALDET_QTY,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					''LS'' AS SALDET_UNIT_DOCNO,
					SCBDET_AMOUNT AS SALDET_RATE,
					0.00 AS SALDET_AMOUNT,--((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					SCBDET_AMOUNT AS SALDET_GROSS_AMOUNT,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					0.00 AS SALDET_DISCOUNT_AMOUNT,--(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					0.00 AS SALDET_DISCOUNT_PERCENT,
					NULL AS SALDET_CAT_REF,
					SCBDET_bill_date AS SALDET_DOCDATE,
					SCBDET_DESC AS SALDET_EXTENDED_DESC,
					SCBDET_DESC AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00 AS SALDET_OTHER_AMOUNT,
					SC_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					SC_DOCTYPE										AS SALDET_PREVIOUS_DOCTYPE,
					SC_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					SCBDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					1												AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					SCBDET_DOCSRNO									AS SALDET_REFONENUMBER,
					SCBDET_BILL_DATE								AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					SC_DIVN_DOCNO									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					SC_DEPT_DOCNO									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					NULL											AS SALDET_SMAN_DOCNO,
					NULL											AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					sc_jobdocno										AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					''AED''											AS SALDET_CURR_DOCNO,
					sc_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					5												AS SALDET_VAT_PERCENTAGE,
					''SR''											AS SALDET_VAT_CATEGORY_DOCNO,
					sc_amount										AS SALDET_CONTRACT_VALUE
			FROM	service_contract_header 
			INNER JOIN service_contract_bill_details ON
					sc_fycode	=	scbdet_fycode	AND
					sc_doctype	=	scbdet_doctype	AND
					sc_docno	=	scbdet_docno					
			INNER JOIN account_master ON
					acmst_docno				= SC_AC_DOCNO
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= SC_AC_DOCNO AND
					sublmst_docno			= ISNULL( SC_SUBLEDGER_DOCNO,SC_AC_DOCNO) 	
			LEFT JOIN division_master Div  ON
					SC_DIVN_DOCNO			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					SC_DEPT_DOCNO			= Dept.dept_docno			
			 LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sc_jobdocno and
					jm2.jobmst_doctype		= ''JOB60''
			WHERE	sc_fycode					= ''' + @strFyCode + ''' AND
					scbdet_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					scbdet_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					ISNULL(NULLIF(sc_document_status_docno,''''),''ACT'') = ''ACT'' AND
					 sc_doctype=''SCCA60'' AND 
					 sc_ac_docno=''AR60'' AND 
					1=1 AND 
					1=1 AND 
					 sc_posted_by is not null AND
					 scbdet_after_docsrno is null'
		
			


		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno					AS DocNo,
				saldet_doctype					AS DocType,
				MAX(saldet_docdate)					AS Date,
				MAX(saldet_subledger_docno)			AS PartyCode,
				MAX(sublmst_desc)					AS Party,				 
				saldet_fycode						AS FyCode,
				MAX(SALDET_REFONENUMBER)			AS [RefNo],
				MAX(SALDET_REFONEDATE)				AS [RefDate],
				MAX(SmanDesc)	 					AS SalesMan	,	
				MAX(SALDET_JOB_DOCNO)				AS JobNo			,
				MAX(jobmst_desc)			AS JobDescription,
				MAX(DivnDesc)	 					AS Division,
				MAX(loc_desc) 						AS Location,
				MAX(SALDET_AMOUNT)					AS Amount,
				MAX(SALDET_CURR_DOCNO)				AS Currency
		FROM	#DetailTable4
		INNER JOIN service_contract_bill_details ON
					saldet_fycode	=	scbdet_fycode	AND
					saldet_doctype	=	scbdet_doctype	AND
					saldet_docno	=	scbdet_docno	AND
					saldet_docsrno	=	scbdet_docsrno
		GROUP BY saldet_fycode,saldet_doctype,saldet_docno
 
  
		SELECT 	#DetailTable4.*,
				#detailtable4.saldet_fycode	AS [Fycode],
				#detailtable4.saldet_doctype	AS [DocType],
				#detailtable4.saldet_docno	AS [DocNo],
				--sal_cr_days,
				SC_AC_DOCNO AS sal_ac_docno,
				SC_SUBLEDGER_DOCNO AS sal_subledger_docno,
				--sal_cost_docno,
				SC_JOBDOCNO AS sal_job_docno,
				--sal_sman_docno,
				SC_CURR_DOCNO AS sal_curr_docno,
				CURR_RATE AS sal_curr_rate,
				SC_NARRATION AS sal_narration,
				--sal_gross_amount,
				--sal_other_amount,
				--sal_net_amount,
				----CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				--sal_location_docno,
				--sal_total_qty,
				--sal_created_by,
				--sal_created_ts,
				'AMC' AS sal_ud_label1,
				--sal_ud_label2,
				--sal_doctype AS sal_ud_label3,
				--sal_docno   AS sal_ud_label4,
				--sal_ud_label5,
				--sal_ud_letter_text,
				SC_DEPT_DOCNO AS sal_dept_docno,
				SC_DIVN_DOCNO AS sal_divn_docno
				--sal_address,
				--0 AS sal_discount_amount,
				--sal_discount_percent,
				--sal_refno,
				--sal_refdate,
				--sal_ship_contact_docno,
				--sal_bill_contact_docno,
				--sal_ship_address,
				--sal_bill_address,
				--sal_ship_addr1,
				--sal_bill_addr1,
				--sal_ship_addr2,
				--sal_bill_addr2,
				--sal_ship_addr3,
				--sal_bill_addr3,
				--sal_ship_city,
				--sal_bill_city,
				--sal_ship_state,
				--sal_bill_state,
				--sal_ship_country,
				--sal_bill_country,
				--sal_ship_street,
				--sal_bill_street,
				--sal_ship_zipcode,
				--sal_bill_zipcode,
				--sal_ship_mobile,
				--sal_bill_mobile,
				--sal_ship_tel1,
				--sal_bill_tel1,
				--sal_ship_tel2,
				--sal_bill_tel2,
				--sal_ship_fax,
				--sal_bill_fax,
				--sal_ship_email,
				--sal_bill_email,
				--sal_paytrm_docno,
				--sal_deltrm_docno,
				--sal_bill_contact_name,
				--sal_ship_contact_name,
				--sal_paytrm_desc,
				--sal_deltrm_desc,
				--sal_document_status_docno,
				--sal_posted_by,
				--sal_posted_ts,
				--sal_paymode_docno,
				--sal_paymode_desc,
				--sal_batch_docno,
				--sal_delivery_date,
				--acmst_desc,
				--sublmst_desc,
				--sal_DOCTYPE as SAL_PREV_DOCTYPE,
				--sal_bill_from_date,
				--sal_bill_to_date,
				--sal_vat_treatment,
				--sal_vat_treatment_docno,
				--sal_vat_rate_type,
				--saldet_vat_percentage,
				--saldet_vat_category_docno	,
				--SAL_ROUNDOFF_AMOUNT,
				--SAL_RETNTION_VAT_ADJUSTMENT,
				--SAL_RETENTION_PERCENT,
				--SAL_RETENTION_AMOUNT
		FROM	#DetailTable4
		INNER JOIN service_contract_header ON 
				sc_fycode				= saldet_fycode  AND
				sc_doctype				= saldet_doctype  AND
				sc_docno				= saldet_docno	
		INNER JOIN service_contract_bill_details ON
				saldet_fycode	=	scbdet_fycode	AND
				saldet_doctype	=	scbdet_doctype	AND
				saldet_docno	=	scbdet_docno	AND
				saldet_docsrno	=	scbdet_docsrno
		INNER JOIN CURRENCY_MASTER ON
				curr_docno	=	SC_CURR_DOCNO
		ORDER by	saldet_docsrno
	END

	IF @strDocType = 'SVIS30'  and @strPrevDocType = 'SCCA30'
	BEGIN
		SET @strSQLString = N'INSERT INTo #DetailTable4
		SELECT			
					SC_FYCODE,
					SC_DOCTYPE,
					SC_DOCNO,
					SCBDET_DOCSRNO,
					''SMNS'',
					''101'',		
					ISNULL(NULLIF(SCBDET_DESC,''''),''NON STOCK ITEM''),
					''31''AS SALDET_LOCATION_DOCNO,
					1 AS SALDET_QTY,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					''LS'' AS SALDET_UNIT_DOCNO,
					SCBDET_AMOUNT AS SALDET_RATE,
					0.00 AS SALDET_AMOUNT,--((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					SCBDET_AMOUNT AS SALDET_GROSS_AMOUNT,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					0.00 AS SALDET_DISCOUNT_AMOUNT,--(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					0.00 AS SALDET_DISCOUNT_PERCENT,
					NULL AS SALDET_CAT_REF,
					SCBDET_bill_date AS SALDET_DOCDATE,
					SCBDET_DESC AS SALDET_EXTENDED_DESC,
					SCBDET_DESC AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00 AS SALDET_OTHER_AMOUNT,
					SC_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					SC_DOCTYPE										AS SALDET_PREVIOUS_DOCTYPE,
					SC_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					SCBDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					1												AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					SCBDET_DOCSRNO									AS SALDET_REFONENUMBER,
					SCBDET_BILL_DATE								AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					SC_DIVN_DOCNO									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					SC_DEPT_DOCNO									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					NULL											AS SALDET_SMAN_DOCNO,
					NULL											AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					sc_jobdocno										AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					''AED''											AS SALDET_CURR_DOCNO,
					sc_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					5												AS SALDET_VAT_PERCENTAGE,
					''SR''											AS SALDET_VAT_CATEGORY_DOCNO,
					sc_amount										AS SALDET_CONTRACT_VALUE
			FROM	service_contract_header 
			INNER JOIN service_contract_bill_details ON
					sc_fycode	=	scbdet_fycode	AND
					sc_doctype	=	scbdet_doctype	AND
					sc_docno	=	scbdet_docno					
			INNER JOIN account_master ON
					acmst_docno				= SC_AC_DOCNO
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= SC_AC_DOCNO AND
					sublmst_docno			= ISNULL( SC_SUBLEDGER_DOCNO,SC_AC_DOCNO) 	
			LEFT JOIN division_master Div  ON
					SC_DIVN_DOCNO			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					SC_DEPT_DOCNO			= Dept.dept_docno			
			 LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sc_jobdocno and
					jm2.jobmst_doctype		= ''JOB30''
			WHERE	sc_fycode					= ''' + @strFyCode + ''' AND
					scbdet_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					scbdet_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					ISNULL(NULLIF(sc_document_status_docno,''''),''ACT'') = ''ACT'' AND
					 sc_doctype=''SCCA30'' AND 
					 sc_ac_docno=''AR30'' AND 
					1=1 AND 
					1=1 AND 
					 sc_posted_by is not null AND
					 scbdet_after_docsrno is null'
		
			


		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno					AS DocNo,
				saldet_doctype					AS DocType,
				MAX(saldet_docdate)					AS Date,
				MAX(saldet_subledger_docno)			AS PartyCode,
				MAX(sublmst_desc)					AS Party,				 
				saldet_fycode						AS FyCode,
				MAX(SALDET_REFONENUMBER)			AS [RefNo],
				MAX(SALDET_REFONEDATE)				AS [RefDate],
				MAX(SmanDesc)	 					AS SalesMan	,	
				MAX(SALDET_JOB_DOCNO)				AS JobNo			,
				MAX(jobmst_desc)			AS JobDescription,
				MAX(DivnDesc)	 					AS Division,
				MAX(loc_desc) 						AS Location,
				MAX(SALDET_AMOUNT)					AS Amount,
				MAX(SALDET_CURR_DOCNO)				AS Currency
		FROM	#DetailTable4
		INNER JOIN service_contract_bill_details ON
					saldet_fycode	=	scbdet_fycode	AND
					saldet_doctype	=	scbdet_doctype	AND
					saldet_docno	=	scbdet_docno	AND
					saldet_docsrno	=	scbdet_docsrno
		GROUP BY saldet_fycode,saldet_doctype,saldet_docno
 
  
		SELECT 	#DetailTable4.*,
				#detailtable4.saldet_fycode	AS [Fycode],
				#detailtable4.saldet_doctype	AS [DocType],
				#detailtable4.saldet_docno	AS [DocNo],
				--sal_cr_days,
				SC_AC_DOCNO AS sal_ac_docno,
				SC_SUBLEDGER_DOCNO AS sal_subledger_docno,
				--sal_cost_docno,
				SC_JOBDOCNO AS sal_job_docno,
				--sal_sman_docno,
				SC_CURR_DOCNO AS sal_curr_docno,
				CURR_RATE AS sal_curr_rate,
				SC_NARRATION AS sal_narration,
				--sal_gross_amount,
				--sal_other_amount,
				--sal_net_amount,
				----CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				--sal_location_docno,
				--sal_total_qty,
				--sal_created_by,
				--sal_created_ts,
				'AMC' AS sal_ud_label1,
				--sal_ud_label2,
				--sal_doctype AS sal_ud_label3,
				--sal_docno   AS sal_ud_label4,
				--sal_ud_label5,
				--sal_ud_letter_text,
				SC_DEPT_DOCNO AS sal_dept_docno,
				SC_DIVN_DOCNO AS sal_divn_docno
				--sal_address,
				--0 AS sal_discount_amount,
				--sal_discount_percent,
				--sal_refno,
				--sal_refdate,
				--sal_ship_contact_docno,
				--sal_bill_contact_docno,
				--sal_ship_address,
				--sal_bill_address,
				--sal_ship_addr1,
				--sal_bill_addr1,
				--sal_ship_addr2,
				--sal_bill_addr2,
				--sal_ship_addr3,
				--sal_bill_addr3,
				--sal_ship_city,
				--sal_bill_city,
				--sal_ship_state,
				--sal_bill_state,
				--sal_ship_country,
				--sal_bill_country,
				--sal_ship_street,
				--sal_bill_street,
				--sal_ship_zipcode,
				--sal_bill_zipcode,
				--sal_ship_mobile,
				--sal_bill_mobile,
				--sal_ship_tel1,
				--sal_bill_tel1,
				--sal_ship_tel2,
				--sal_bill_tel2,
				--sal_ship_fax,
				--sal_bill_fax,
				--sal_ship_email,
				--sal_bill_email,
				--sal_paytrm_docno,
				--sal_deltrm_docno,
				--sal_bill_contact_name,
				--sal_ship_contact_name,
				--sal_paytrm_desc,
				--sal_deltrm_desc,
				--sal_document_status_docno,
				--sal_posted_by,
				--sal_posted_ts,
				--sal_paymode_docno,
				--sal_paymode_desc,
				--sal_batch_docno,
				--sal_delivery_date,
				--acmst_desc,
				--sublmst_desc,
				--sal_DOCTYPE as SAL_PREV_DOCTYPE,
				--sal_bill_from_date,
				--sal_bill_to_date,
				--sal_vat_treatment,
				--sal_vat_treatment_docno,
				--sal_vat_rate_type,
				--saldet_vat_percentage,
				--saldet_vat_category_docno	,
				--SAL_ROUNDOFF_AMOUNT,
				--SAL_RETNTION_VAT_ADJUSTMENT,
				--SAL_RETENTION_PERCENT,
				--SAL_RETENTION_AMOUNT
		FROM	#DetailTable4
		INNER JOIN service_contract_header ON 
				sc_fycode				= saldet_fycode  AND
				sc_doctype				= saldet_doctype  AND
				sc_docno				= saldet_docno	
		INNER JOIN service_contract_bill_details ON
				saldet_fycode	=	scbdet_fycode	AND
				saldet_doctype	=	scbdet_doctype	AND
				saldet_docno	=	scbdet_docno	AND
				saldet_docsrno	=	scbdet_docsrno
		INNER JOIN CURRENCY_MASTER ON
				curr_docno	=	SC_CURR_DOCNO
		ORDER by	saldet_docsrno
	END

	IF @strDocType IN('SVIS30') and @strPrevDocType = 'SVQS30'
	BEGIN
	PRINT 'Sales invoice SVQS30'
		SET @strSQLString = N'INSERT INTo #DetailTable5
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					''1'',--SALDET_DOCSRNO,
					MAX(SALDET_STOCK_DOCTYPE) as SALDET_STOCK_DOCTYPE,
					MAX(SALDET_STOCK_DOCNO) as SALDET_STOCK_DOCNO,		
					MAX(SALDET_STOCK_DESC) as SALDET_STOCK_DESC,
					CASE WHEN '''+@strDocType+''' =''SI'' then MAX(SALDET_LOCATION_DOCNO) else
					ISNULL(NULLIF(MAX(SALDET_LOCATION_DOCNO),''''),''' + ISNULL(@strDefaultLocation,'') + ''') end AS SALDET_LOCATION_DOCNO,
					(MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) SALDET_QTY,
					MAX(SALDET_UNIT_DOCNO),
					MAX(SALDET_RATE),
					((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE)) - ((((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE))* MAX(SALDET_DISCOUNT_PERCENT))/100)  AS SALDET_AMOUNT,
					(MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE) AS SALDET_GROSS_AMOUNT,
					(((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE))* MAX(SALDET_DISCOUNT_PERCENT))/100 AS SALDET_DISCOUNT_AMOUNT,
					MAX(SALDET_DISCOUNT_PERCENT) AS SALDET_DISCOUNT_PERCENT,
					MAX(SALDET_CAT_REF),
					GETDATE(),
					MAX(SALDET_EXTENDED_DESC),
					MAX(SALDET_REMARKS),
					MAX(SALDET_CUSTOMER_REFDESC),
					MAX(SALDET_BATCH_DOCNO),
					MAX(SALDET_OTHER_AMOUNT),
					MAX(SALDET_FYCODE)									AS SALDET_PREVIOUS_FYCODE,
					MAX(SALDET_DOCTYPE)									AS SALDET_PREVIOUS_DOCTYPE,
					MAX(SALDET_DOCNO)									AS SALDET_PREVIOUS_DOCNO,
					MAX(SALDET_DOCSRNO)									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					MAX(SALDET_QTY) - ISNULL( MAX(SALDET_AFTER_DOC_QTY),0)	AS BEFOREQTY,
					MAX(acmst_desc)										AS ACMST_DESC,
					MAX(SUBLMST_DESC)									AS SUBLMST_DESC,
					MAX(acmst_divn_docno)								AS FIXED_DIVISION,
					MAX(sal_refno)										AS SALDET_REFONENUMBER,
					MAX(sal_refdate)										AS SALDET_REFONEDATE,
					--MAX(sal_ref2)										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					MAX(sal_divn_docno)									AS SALDET_DIVN_DOCNO,
					MAX(divn_desc)										AS SALDET_DIVN_DESC,
					MAX(sal_dept_docno)									AS SALDET_DEPT_DOCNO,
					MAX(dept_desc)										AS SALDET_DEPT_DESC,
					NULL											AS DOCSTAUS,
					MAX(sal_sman_docno)									AS SALDET_SMAN_DOCNO,
					MAX(sman_Desc)										AS SALDET_SMAN_DESC,
					MAX(location_master.loc_desc)						AS SALDET_LOC_DESC,
					MAX(sal_job_docno)									AS SALDET_JOB_DOCNO,
					MAX(jobmst_desc)										AS SALDET_JOBMST_DESC,
					MAX(sal_curr_docno)									AS SALDET_CURR_DOCNO,
					MAX(sal_subledger_docno)								AS SALDET_SUBLEDGER_DOCNO,					
					MAX(SALDET_VAT_PERCENTAGE),
					MAX(SALDET_VAT_CATEGORY_DOCNO)	,
					MAX(JOBMST_BUDJ_INCOME)						
			FROM	SALES_DETAILS' 
	SET @strSQLString = @strSQLString +		' INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno
			LEFT OUTER JOIN job_master   on
					jobmst_docno		=  sal_job_docno 
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##GROUPBY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null  ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		--SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

			SET @strSQLString = REPLACE( @strSQLString, '##GROUPBY##',  ' GROUP BY SALDET_FYCODE,SALDET_DOCTYPE,SALDET_DOCNO' )		

 			



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable5
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable5.*,
				#detailtable5.saldet_fycode		AS [Fycode],
				#detailtable5.saldet_doctype	AS [DocType],
				#detailtable5.saldet_docno		AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				'SJOB' AS sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				NULL AS sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno	,
				SAL_ROUNDOFF_AMOUNT,
				SAL_RETNTION_VAT_ADJUSTMENT,
				SAL_RETENTION_PERCENT,
				SAL_RETENTION_AMOUNT
		FROM	#DetailTable5
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END

	IF @strDocType IN('SVIS40') and @strPrevDocType = 'SVQS40'
	BEGIN
	PRINT 'Sales invoice SVQS40'
	--raiserror('test',16,1)
		SET @strSQLString = N'INSERT INTo #DetailTable5
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					''1'',--SALDET_DOCSRNO,
					MAX(SALDET_STOCK_DOCTYPE) as SALDET_STOCK_DOCTYPE,
					MAX(SALDET_STOCK_DOCNO) as SALDET_STOCK_DOCNO,		
					MAX(SALDET_STOCK_DESC) as SALDET_STOCK_DESC,
					CASE WHEN '''+@strDocType+''' =''SI'' then MAX(SALDET_LOCATION_DOCNO) else
					ISNULL(NULLIF(MAX(SALDET_LOCATION_DOCNO),''''),''' + ISNULL(@strDefaultLocation,'') + ''') end AS SALDET_LOCATION_DOCNO,
					(MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) SALDET_QTY,
					MAX(SALDET_UNIT_DOCNO),
					MAX(SALDET_AMOUNT) AS SALDET_RATE,
					((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE)) - ((((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE))* MAX(SALDET_DISCOUNT_PERCENT))/100)  AS SALDET_AMOUNT,
					(MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE) AS SALDET_GROSS_AMOUNT,
					(((MAX(saldet_qty) - ISNULL( MAX(saldet_after_doc_qty3),0)) * MAX(SALDET_RATE))* MAX(SALDET_DISCOUNT_PERCENT))/100 AS SALDET_DISCOUNT_AMOUNT,
					MAX(SALDET_DISCOUNT_PERCENT) AS SALDET_DISCOUNT_PERCENT,
					MAX(SALDET_CAT_REF),
					GETDATE(),
					MAX(SALDET_EXTENDED_DESC),
					MAX(SALDET_REMARKS),
					MAX(SALDET_CUSTOMER_REFDESC),
					MAX(SALDET_BATCH_DOCNO),
					MAX(SALDET_OTHER_AMOUNT),
					MAX(SALDET_FYCODE)									AS SALDET_PREVIOUS_FYCODE,
					MAX(SALDET_DOCTYPE)									AS SALDET_PREVIOUS_DOCTYPE,
					MAX(SALDET_DOCNO)									AS SALDET_PREVIOUS_DOCNO,
					MAX(SALDET_DOCSRNO)									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					MAX(SALDET_QTY) - ISNULL( MAX(SALDET_AFTER_DOC_QTY),0)	AS BEFOREQTY,
					MAX(acmst_desc)										AS ACMST_DESC,
					MAX(SUBLMST_DESC)									AS SUBLMST_DESC,
					MAX(acmst_divn_docno)								AS FIXED_DIVISION,
					MAX(sal_refno)										AS SALDET_REFONENUMBER,
					MAX(sal_refdate)										AS SALDET_REFONEDATE,
					--MAX(sal_ref2)										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					MAX(sal_divn_docno)									AS SALDET_DIVN_DOCNO,
					MAX(divn_desc)										AS SALDET_DIVN_DESC,
					MAX(sal_dept_docno)									AS SALDET_DEPT_DOCNO,
					MAX(dept_desc)										AS SALDET_DEPT_DESC,
					NULL											AS DOCSTAUS,
					MAX(sal_sman_docno)									AS SALDET_SMAN_DOCNO,
					MAX(sman_Desc)										AS SALDET_SMAN_DESC,
					MAX(location_master.loc_desc)						AS SALDET_LOC_DESC,
					MAX(sal_job_docno)									AS SALDET_JOB_DOCNO,
					MAX(jobmst_desc)										AS SALDET_JOBMST_DESC,
					MAX(sal_curr_docno)									AS SALDET_CURR_DOCNO,
					MAX(sal_subledger_docno)								AS SALDET_SUBLEDGER_DOCNO,					
					MAX(SALDET_VAT_PERCENTAGE),
					MAX(SALDET_VAT_CATEGORY_DOCNO)	,
					MAX(JOBMST_BUDJ_INCOME)						
			FROM	SALES_DETAILS' 
	SET @strSQLString = @strSQLString +		' INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno=sal_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno
			LEFT OUTER JOIN job_master   on
					jobmst_docno		=  sal_job_docno 
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##GROUPBY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null  ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		--SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty3,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

			SET @strSQLString = REPLACE( @strSQLString, '##GROUPBY##',  ' GROUP BY SALDET_FYCODE,SALDET_DOCTYPE,SALDET_DOCNO' )		

 			



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable5
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable5.*,
				#detailtable5.saldet_fycode		AS [Fycode],
				#detailtable5.saldet_doctype	AS [DocType],
				#detailtable5.saldet_docno		AS [DocNo],
				SALDET_AMOUNT					AS SALDET_RATE,
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				--CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				'SJOB' AS sal_ud_label1,
				sal_ud_label2,
				sal_doctype AS sal_ud_label3,
				sal_docno   AS sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_address,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_delivery_date,
				acmst_desc,
				sublmst_desc,
				sal_DOCTYPE as SAL_PREV_DOCTYPE,
				sal_bill_from_date,
				sal_bill_to_date,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno	,
				SAL_ROUNDOFF_AMOUNT,
				SAL_RETNTION_VAT_ADJUSTMENT,
				SAL_RETENTION_PERCENT,
				SAL_RETENTION_AMOUNT
		FROM	#DetailTable5
		 
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
	END

	IF @strDocType = 'SVIS40'  and @strPrevDocType = 'SCCA40'
	BEGIN
		SET @strSQLString = N'INSERT INTo #DetailTable4
		SELECT			
					SC_FYCODE,
					SC_DOCTYPE,
					SC_DOCNO,
					SCBDET_DOCSRNO,
					''SMNS'',
					''101'',		
					ISNULL(NULLIF(SCBDET_DESC,''''),''NON STOCK ITEM''),
					''31''AS SALDET_LOCATION_DOCNO,
					1 AS SALDET_QTY,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					''LS'' AS SALDET_UNIT_DOCNO,
					SCBDET_AMOUNT AS SALDET_RATE,
					0.00 AS SALDET_AMOUNT,--((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					SCBDET_AMOUNT AS SALDET_GROSS_AMOUNT,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					0.00 AS SALDET_DISCOUNT_AMOUNT,--(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					0.00 AS SALDET_DISCOUNT_PERCENT,
					NULL AS SALDET_CAT_REF,
					SCBDET_bill_date AS SALDET_DOCDATE,
					SCBDET_DESC AS SALDET_EXTENDED_DESC,
					SCBDET_DESC AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00 AS SALDET_OTHER_AMOUNT,
					SC_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					SC_DOCTYPE										AS SALDET_PREVIOUS_DOCTYPE,
					SC_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					SCBDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					1												AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					SCBDET_DOCSRNO									AS SALDET_REFONENUMBER,
					SCBDET_BILL_DATE								AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					SC_DIVN_DOCNO									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					SC_DEPT_DOCNO									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					NULL											AS SALDET_SMAN_DOCNO,
					NULL											AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					sc_jobdocno										AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					''AED''											AS SALDET_CURR_DOCNO,
					sc_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					5												AS SALDET_VAT_PERCENTAGE,
					''SR''											AS SALDET_VAT_CATEGORY_DOCNO,
					sc_amount										AS SALDET_CONTRACT_VALUE
			FROM	service_contract_header 
			INNER JOIN service_contract_bill_details ON
					sc_fycode	=	scbdet_fycode	AND
					sc_doctype	=	scbdet_doctype	AND
					sc_docno	=	scbdet_docno					
			INNER JOIN account_master ON
					acmst_docno				= SC_AC_DOCNO
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= SC_AC_DOCNO AND
					sublmst_docno			= ISNULL( SC_SUBLEDGER_DOCNO,SC_AC_DOCNO) 	
			LEFT JOIN division_master Div  ON
					SC_DIVN_DOCNO			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					SC_DEPT_DOCNO			= Dept.dept_docno			
			 LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sc_jobdocno and
					jm2.jobmst_doctype		= ''JOB30''
			WHERE	sc_fycode					= ''' + @strFyCode + ''' AND
					scbdet_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					scbdet_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					ISNULL(NULLIF(sc_document_status_docno,''''),''ACT'') = ''ACT'' AND
					 sc_doctype=''SCCA30'' AND 
					 sc_ac_docno=''AR30'' AND 
					1=1 AND 
					1=1 AND 
					 sc_posted_by is not null AND
					 scbdet_after_docsrno is null'
		
			


		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno					AS DocNo,
				saldet_doctype					AS DocType,
				MAX(saldet_docdate)					AS Date,
				MAX(saldet_subledger_docno)			AS PartyCode,
				MAX(sublmst_desc)					AS Party,				 
				saldet_fycode						AS FyCode,
				MAX(SALDET_REFONENUMBER)			AS [RefNo],
				MAX(SALDET_REFONEDATE)				AS [RefDate],
				MAX(SmanDesc)	 					AS SalesMan	,	
				MAX(SALDET_JOB_DOCNO)				AS JobNo			,
				MAX(jobmst_desc)			AS JobDescription,
				MAX(DivnDesc)	 					AS Division,
				MAX(loc_desc) 						AS Location,
				MAX(SALDET_AMOUNT)					AS Amount,
				MAX(SALDET_CURR_DOCNO)				AS Currency
		FROM	#DetailTable4
		INNER JOIN service_contract_bill_details ON
					saldet_fycode	=	scbdet_fycode	AND
					saldet_doctype	=	scbdet_doctype	AND
					saldet_docno	=	scbdet_docno	AND
					saldet_docsrno	=	scbdet_docsrno
		GROUP BY saldet_fycode,saldet_doctype,saldet_docno
 
  
		SELECT 	#DetailTable4.*,
				#detailtable4.saldet_fycode	AS [Fycode],
				#detailtable4.saldet_doctype	AS [DocType],
				#detailtable4.saldet_docno	AS [DocNo],
				--sal_cr_days,
				SC_AC_DOCNO AS sal_ac_docno,
				SC_SUBLEDGER_DOCNO AS sal_subledger_docno,
				--sal_cost_docno,
				SC_JOBDOCNO AS sal_job_docno,
				--sal_sman_docno,
				SC_CURR_DOCNO AS sal_curr_docno,
				CURR_RATE AS sal_curr_rate,
				SC_NARRATION AS sal_narration,
				--sal_gross_amount,
				--sal_other_amount,
				--sal_net_amount,
				----CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				--sal_location_docno,
				--sal_total_qty,
				--sal_created_by,
				--sal_created_ts,
				'AMC' AS sal_ud_label1,
				--sal_ud_label2,
				--sal_doctype AS sal_ud_label3,
				--sal_docno   AS sal_ud_label4,
				--sal_ud_label5,
				--sal_ud_letter_text,
				SC_DEPT_DOCNO AS sal_dept_docno,
				SC_DIVN_DOCNO AS sal_divn_docno
				--sal_address,
				--0 AS sal_discount_amount,
				--sal_discount_percent,
				--sal_refno,
				--sal_refdate,
				--sal_ship_contact_docno,
				--sal_bill_contact_docno,
				--sal_ship_address,
				--sal_bill_address,
				--sal_ship_addr1,
				--sal_bill_addr1,
				--sal_ship_addr2,
				--sal_bill_addr2,
				--sal_ship_addr3,
				--sal_bill_addr3,
				--sal_ship_city,
				--sal_bill_city,
				--sal_ship_state,
				--sal_bill_state,
				--sal_ship_country,
				--sal_bill_country,
				--sal_ship_street,
				--sal_bill_street,
				--sal_ship_zipcode,
				--sal_bill_zipcode,
				--sal_ship_mobile,
				--sal_bill_mobile,
				--sal_ship_tel1,
				--sal_bill_tel1,
				--sal_ship_tel2,
				--sal_bill_tel2,
				--sal_ship_fax,
				--sal_bill_fax,
				--sal_ship_email,
				--sal_bill_email,
				--sal_paytrm_docno,
				--sal_deltrm_docno,
				--sal_bill_contact_name,
				--sal_ship_contact_name,
				--sal_paytrm_desc,
				--sal_deltrm_desc,
				--sal_document_status_docno,
				--sal_posted_by,
				--sal_posted_ts,
				--sal_paymode_docno,
				--sal_paymode_desc,
				--sal_batch_docno,
				--sal_delivery_date,
				--acmst_desc,
				--sublmst_desc,
				--sal_DOCTYPE as SAL_PREV_DOCTYPE,
				--sal_bill_from_date,
				--sal_bill_to_date,
				--sal_vat_treatment,
				--sal_vat_treatment_docno,
				--sal_vat_rate_type,
				--saldet_vat_percentage,
				--saldet_vat_category_docno	,
				--SAL_ROUNDOFF_AMOUNT,
				--SAL_RETNTION_VAT_ADJUSTMENT,
				--SAL_RETENTION_PERCENT,
				--SAL_RETENTION_AMOUNT
		FROM	#DetailTable4
		INNER JOIN service_contract_header ON 
				sc_fycode				= saldet_fycode  AND
				sc_doctype				= saldet_doctype  AND
				sc_docno				= saldet_docno	
		INNER JOIN service_contract_bill_details ON
				saldet_fycode	=	scbdet_fycode	AND
				saldet_doctype	=	scbdet_doctype	AND
				saldet_docno	=	scbdet_docno	AND
				saldet_docsrno	=	scbdet_docsrno
		INNER JOIN CURRENCY_MASTER ON
				curr_docno	=	SC_CURR_DOCNO
		ORDER by	saldet_docsrno
	END

	IF @strDocType = 'SVIS20'  and @strPrevDocType = 'SCCA20'
	BEGIN
		SET @strSQLString = N'INSERT INTo #DetailTable4
		SELECT			
					SC_FYCODE,
					SC_DOCTYPE,
					SC_DOCNO,
					SCBDET_DOCSRNO,
					''SMNS'',
					''101'',		
					ISNULL(NULLIF(SCBDET_DESC,''''),''NON STOCK ITEM''),
					''31''AS SALDET_LOCATION_DOCNO,
					1 AS SALDET_QTY,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) SALDET_QTY,
					''LS'' AS SALDET_UNIT_DOCNO,
					SCBDET_AMOUNT AS SALDET_RATE,
					0.00 AS SALDET_AMOUNT,--((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE) - ((((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100)  AS SALDET_AMOUNT,
					SCBDET_AMOUNT AS SALDET_GROSS_AMOUNT,--(saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					0.00 AS SALDET_DISCOUNT_AMOUNT,--(((saldet_qty - ISNULL( saldet_after_doc_qty3,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					0.00 AS SALDET_DISCOUNT_PERCENT,
					NULL AS SALDET_CAT_REF,
					SCBDET_bill_date AS SALDET_DOCDATE,
					SCBDET_DESC AS SALDET_EXTENDED_DESC,
					SCBDET_DESC AS SALDET_REMARKS,
					NULL AS SALDET_CUSTOMER_REFDESC,
					NULL AS SALDET_BATCH_DOCNO,
					0.00 AS SALDET_OTHER_AMOUNT,
					SC_FYCODE										AS SALDET_PREVIOUS_FYCODE,
					SC_DOCTYPE										AS SALDET_PREVIOUS_DOCTYPE,
					SC_DOCNO										AS SALDET_PREVIOUS_DOCNO,
					SCBDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					1												AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					SCBDET_DOCSRNO									AS SALDET_REFONENUMBER,
					SCBDET_BILL_DATE								AS SALDET_REFONEDATE,
					--sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					SC_DIVN_DOCNO									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					SC_DEPT_DOCNO									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					NULL											AS SALDET_SMAN_DOCNO,
					NULL											AS SALDET_SMAN_DESC,
					NULL											AS SALDET_LOC_DESC,
					sc_jobdocno										AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					''AED''											AS SALDET_CURR_DOCNO,
					sc_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					5												AS SALDET_VAT_PERCENTAGE,
					''SR''											AS SALDET_VAT_CATEGORY_DOCNO,
					sc_amount										AS SALDET_CONTRACT_VALUE
			FROM	service_contract_header 
			INNER JOIN service_contract_bill_details ON
					sc_fycode	=	scbdet_fycode	AND
					sc_doctype	=	scbdet_doctype	AND
					sc_docno	=	scbdet_docno					
			INNER JOIN account_master ON
					acmst_docno				= SC_AC_DOCNO
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= SC_AC_DOCNO AND
					sublmst_docno			= ISNULL( SC_SUBLEDGER_DOCNO,SC_AC_DOCNO) 	
			LEFT JOIN division_master Div  ON
					SC_DIVN_DOCNO			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					SC_DEPT_DOCNO			= Dept.dept_docno			
			 LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sc_jobdocno and
					jm2.jobmst_doctype		= ''JOB20''
			WHERE	sc_fycode					= ''' + @strFyCode + ''' AND
					scbdet_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					scbdet_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					ISNULL(NULLIF(sc_document_status_docno,''''),''ACT'') = ''ACT'' AND
					 sc_doctype=''SCCA20'' AND 
					 sc_ac_docno=''AR20'' AND 
					1=1 AND 
					1=1 AND 
					 sc_posted_by is not null AND
					 scbdet_after_docsrno is null'
		
			


		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno					AS DocNo,
				saldet_doctype					AS DocType,
				MAX(saldet_docdate)					AS Date,
				MAX(saldet_subledger_docno)			AS PartyCode,
				MAX(sublmst_desc)					AS Party,				 
				saldet_fycode						AS FyCode,
				MAX(SALDET_REFONENUMBER)			AS [RefNo],
				MAX(SALDET_REFONEDATE)				AS [RefDate],
				MAX(SmanDesc)	 					AS SalesMan	,	
				MAX(SALDET_JOB_DOCNO)				AS JobNo			,
				MAX(jobmst_desc)			AS JobDescription,
				MAX(DivnDesc)	 					AS Division,
				MAX(loc_desc) 						AS Location,
				MAX(SALDET_AMOUNT)					AS Amount,
				MAX(SALDET_CURR_DOCNO)				AS Currency
		FROM	#DetailTable4
		INNER JOIN service_contract_bill_details ON
					saldet_fycode	=	scbdet_fycode	AND
					saldet_doctype	=	scbdet_doctype	AND
					saldet_docno	=	scbdet_docno	AND
					saldet_docsrno	=	scbdet_docsrno
		GROUP BY saldet_fycode,saldet_doctype,saldet_docno
 
  
		SELECT 	#DetailTable4.*,
				#detailtable4.saldet_fycode	AS [Fycode],
				#detailtable4.saldet_doctype	AS [DocType],
				#detailtable4.saldet_docno	AS [DocNo],
				--sal_cr_days,
				SC_AC_DOCNO AS sal_ac_docno,
				SC_SUBLEDGER_DOCNO AS sal_subledger_docno,
				--sal_cost_docno,
				SC_JOBDOCNO AS sal_job_docno,
				--sal_sman_docno,
				SC_CURR_DOCNO AS sal_curr_docno,
				CURR_RATE AS sal_curr_rate,
				SC_NARRATION AS sal_narration,
				--sal_gross_amount,
				--sal_other_amount,
				--sal_net_amount,
				----CASE WHEN @strDocType ='SI' then '103' else sal_location_docno END AS sal_location_docno,
				--sal_location_docno,
				--sal_total_qty,
				--sal_created_by,
				--sal_created_ts,
				'AMC' AS sal_ud_label1,
				--sal_ud_label2,
				--sal_doctype AS sal_ud_label3,
				--sal_docno   AS sal_ud_label4,
				--sal_ud_label5,
				--sal_ud_letter_text,
				SC_DEPT_DOCNO AS sal_dept_docno,
				SC_DIVN_DOCNO AS sal_divn_docno
				--sal_address,
				--0 AS sal_discount_amount,
				--sal_discount_percent,
				--sal_refno,
				--sal_refdate,
				--sal_ship_contact_docno,
				--sal_bill_contact_docno,
				--sal_ship_address,
				--sal_bill_address,
				--sal_ship_addr1,
				--sal_bill_addr1,
				--sal_ship_addr2,
				--sal_bill_addr2,
				--sal_ship_addr3,
				--sal_bill_addr3,
				--sal_ship_city,
				--sal_bill_city,
				--sal_ship_state,
				--sal_bill_state,
				--sal_ship_country,
				--sal_bill_country,
				--sal_ship_street,
				--sal_bill_street,
				--sal_ship_zipcode,
				--sal_bill_zipcode,
				--sal_ship_mobile,
				--sal_bill_mobile,
				--sal_ship_tel1,
				--sal_bill_tel1,
				--sal_ship_tel2,
				--sal_bill_tel2,
				--sal_ship_fax,
				--sal_bill_fax,
				--sal_ship_email,
				--sal_bill_email,
				--sal_paytrm_docno,
				--sal_deltrm_docno,
				--sal_bill_contact_name,
				--sal_ship_contact_name,
				--sal_paytrm_desc,
				--sal_deltrm_desc,
				--sal_document_status_docno,
				--sal_posted_by,
				--sal_posted_ts,
				--sal_paymode_docno,
				--sal_paymode_desc,
				--sal_batch_docno,
				--sal_delivery_date,
				--acmst_desc,
				--sublmst_desc,
				--sal_DOCTYPE as SAL_PREV_DOCTYPE,
				--sal_bill_from_date,
				--sal_bill_to_date,
				--sal_vat_treatment,
				--sal_vat_treatment_docno,
				--sal_vat_rate_type,
				--saldet_vat_percentage,
				--saldet_vat_category_docno	,
				--SAL_ROUNDOFF_AMOUNT,
				--SAL_RETNTION_VAT_ADJUSTMENT,
				--SAL_RETENTION_PERCENT,
				--SAL_RETENTION_AMOUNT
		FROM	#DetailTable4
		INNER JOIN service_contract_header ON 
				sc_fycode				= saldet_fycode  AND
				sc_doctype				= saldet_doctype  AND
				sc_docno				= saldet_docno	
		INNER JOIN service_contract_bill_details ON
				saldet_fycode	=	scbdet_fycode	AND
				saldet_doctype	=	scbdet_doctype	AND
				saldet_docno	=	scbdet_docno	AND
				saldet_docsrno	=	scbdet_docsrno
		INNER JOIN CURRENCY_MASTER ON
				curr_docno	=	SC_CURR_DOCNO
		ORDER by	saldet_docsrno
	END

	IF @strDocType LIKE 'PFI%'
	BEGIN
	--RAISERROR('HERE',16,1)
		SET @strSQLString = N'INSERT INTo #DetailTable6
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					(saldet_qty - ISNULL( saldet_after_doc_qty,0)) * SALDET_RATE AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_AC_DOCNO,
					SALDET_COUNTRY_ORIGIN_DOCNO,
					SALDET_COUNTRY_ORIGIN_DESC,
					SALDET_MESSAGE,
					SALDET_NOTE,
					SALDET_CONVERSION_QTY2,
					SALDET_ITEM_BRAND,
					SALDET_ITEM_COUNTRY,
					SALDET_ITEM_SIZE,
					SALDET_ITEM_REF,
					SALDET_SIGN,
					NULLIF(SALDET_GRP_HEADEING1,'''') SALDET_GRP_HEADEING1,
					SALDET_GRP_QTY,
					SALDET_GRP_UNIT,
					SALDET_GRP_CATREF,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE			,
					SALDET_VAT_CATEGORY_DOCNO,
					saldet_job_docno2								AS SALDET_JOB_DOCNO2
						
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno = saldet_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable6
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable6.*,
				#DetailTable6.saldet_fycode	AS [Fycode],
				#DetailTable6.saldet_doctype	AS [DocType],
				#DetailTable6.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_ref,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_ud_label3,
				sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_ref2,
				sal_address,
				sal_qotno,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_total_amount,
				sal_bid_due_date,
				sal_contact_docno,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_prev_docno,
				sal_prev_doctype,
				sal_prev_fycode,
				sal_prev_docdate,
				sal_reference1,
				sal_reference2,
				sal_reference3,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_shipto_subledger_docno,
				sal_active_status,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_tax_percentage,
				sal_tax_amount,
				sal_delivery_date,
				sal_contact_name,
				sal_previous_docno,
				sal_ref1,
				sal_sman_desc,
				sal_mob_no,
				sal_payment_mode_docno,
				sal_estimator,
				sal_chasis_no,
				acmst_desc,
				sublmst_desc,
				sal_wt_amount,
				sal_trailer_no,
				sal_docno sal_prev_docno,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno 
		FROM	#DetailTable6
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
		END

	ELSE IF (@strDocType NOT LIKE 'SI%' AND @strDocType NOT LIKE 'SVIS%' AND @strDocType NOT LIKE '%SVRS%' AND @strDocType not in ('AEST60'))
	BEGIN
	--RAISERROR('HERE',16,1)
		SET @strSQLString = N'INSERT INTo #DetailTable6
			SELECT			
					SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					SALDET_STOCK_DESC,
					SALDET_LOCATION_DOCNO,
					(saldet_qty - ISNULL( saldet_after_doc_qty,0)) SALDET_QTY,
					SALDET_UNIT_DOCNO,
					SALDET_RATE,
					(saldet_qty - ISNULL( saldet_after_doc_qty,0)) * SALDET_RATE AS SALDET_AMOUNT,
					(saldet_qty - ISNULL( saldet_after_doc_qty,0)) * SALDET_RATE AS SALDET_GROSS_AMOUNT,
					(((saldet_qty - ISNULL( saldet_after_doc_qty,0)) * SALDET_RATE)* SALDET_DISCOUNT_PERCENT)/100 AS SALDET_DISCOUNT_AMOUNT,
					SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					SALDET_AC_DOCNO,
					SALDET_COUNTRY_ORIGIN_DOCNO,
					SALDET_COUNTRY_ORIGIN_DESC,
					SALDET_MESSAGE,
					SALDET_NOTE,
					SALDET_CONVERSION_QTY2,
					SALDET_ITEM_BRAND,
					SALDET_ITEM_COUNTRY,
					SALDET_ITEM_SIZE,
					SALDET_ITEM_REF,
					SALDET_SIGN,
					NULLIF(SALDET_GRP_HEADEING1,'''') SALDET_GRP_HEADEING1,
					SALDET_GRP_QTY,
					SALDET_GRP_UNIT,
					SALDET_GRP_CATREF,
					SALDET_OTHER_AMOUNT,
					SALDET_FYCODE									AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE									AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO									AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO									AS SALDET_PREVIOUS_DOCSRNO,
					0												AS SALDET_AFTER_DOC_QTY,
					0												AS AFTERDOCQTY,
					0												AS RESERVEDQTY,
					SALDET_QTY - ISNULL( SALDET_AFTER_DOC_QTY,0)	AS BEFOREQTY,
					acmst_desc										AS ACMST_DESC,
					SUBLMST_DESC									AS SUBLMST_DESC,
					acmst_divn_docno								AS FIXED_DIVISION,

					sal_refno										AS SALDET_REFONENUMBER,
					sal_refdate										AS SALDET_REFONEDATE,
					sal_ref2										AS SALDET_REFTWONUMBER,
					NUll											AS SALDET_REFTWODATE,
					sal_divn_docno									AS SALDET_DIVN_DOCNO,
					divn_desc										AS SALDET_DIVN_DESC,
					sal_dept_docno									AS SALDET_DEPT_DOCNO,
					dept_desc										AS SALDET_DEPT_DESC,
					Null											AS DOCSTAUS,
					sal_sman_docno									AS SALDET_SMAN_DOCNO,
					sman_Desc										AS SALDET_SMAN_DESC,
					location_master.loc_desc						AS SALDET_LOC_DESC,
					sal_job_docno									AS SALDET_JOB_DOCNO,
					jobmst_desc										AS SALDET_JOBMST_DESC,
					sal_curr_docno									AS SALDET_CURR_DOCNO,
					sal_subledger_docno								AS SALDET_SUBLEDGER_DOCNO,					
					SALDET_VAT_PERCENTAGE			,
					SALDET_VAT_CATEGORY_DOCNO,
					saldet_job_docno2								AS SALDET_JOB_DOCNO2
						
			FROM	SALES_DETAILS 
			INNER JOIN SALES_HEADER ON
					saldet_fycode= SAL_FYCODE AND
					SALDET_DOCTYPE = SAL_DOCTYPE AND
					saldet_docno= sal_docno 
			INNER JOIN stock_master STK  ON 
					stk.stkmst_doctype		= saldet_stock_doctype AND
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno = saldet_location_docno 
			INNER JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT OUTER JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
			LEFT OUTER JOIN job_master JM2  on
					jm2.jobmst_docno		=  sal_job_docno and
					jm2.jobmst_doctype  = ''JOB''
			##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		IF LEFT(LTRIM(@strDocType),2) = 'SR'
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is not null AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
			
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty,0)) > 0 ' )

		IF @strSourceDocType NOT IN ('DIT')
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  ' INNER JOIN LOCATION_MASTER EST ON EST.LOC_DOCNO = SAL_ESTIMATOR' )		

 



		PRINt (@strSQLString)
		EXEC(@strSQLString  )
					

	
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc)						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( SALDET_REFONENUMBER)				AS [RefNo],
				MAX( SALDET_REFONEDATE)					AS [RefDate],
				MAX( SmanDesc)	 						AS SalesMan	,	
				MAX( SALDET_JOB_DOCNO)					AS JobNo			,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( SALDET_AMOUNT)						AS Amount,
				MAX( SALDET_CURR_DOCNO)					AS Currency
		FROM	#DetailTable6
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
 
  
		SELECT 	#DetailTable6.*,
				#DetailTable6.saldet_fycode	AS [Fycode],
				#DetailTable6.saldet_doctype	AS [DocType],
				#DetailTable6.saldet_docno	AS [DocNo],
				sal_cr_days,
				sal_ac_docno,
				sal_subledger_docno,
				sal_cost_docno,
				sal_job_docno,
				sal_ref,
				sal_sman_docno,
				sal_curr_docno,
				sal_curr_rate,
				sal_narration,
				sal_gross_amount,
				sal_other_amount,
				sal_net_amount,
				sal_location_docno,
				sal_total_qty,
				sal_created_by,
				sal_created_ts,
				sal_ud_label1,
				sal_ud_label2,
				sal_ud_label3,
				sal_ud_label4,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_dept_docno,
				sal_divn_docno,
				sal_ref2,
				sal_address,
				sal_qotno,
				0 AS sal_discount_amount,
				sal_discount_percent,
				sal_refno,
				sal_refdate,
				sal_total_amount,
				sal_bid_due_date,
				sal_contact_docno,
				sal_ship_contact_docno,
				sal_bill_contact_docno,
				sal_ship_address,
				sal_bill_address,
				sal_ship_addr1,
				sal_bill_addr1,
				sal_ship_addr2,
				sal_bill_addr2,
				sal_ship_addr3,
				sal_bill_addr3,
				sal_ship_city,
				sal_bill_city,
				sal_ship_state,
				sal_bill_state,
				sal_ship_country,
				sal_bill_country,
				sal_ship_street,
				sal_bill_street,
				sal_ship_zipcode,
				sal_bill_zipcode,
				sal_ship_mobile,
				sal_bill_mobile,
				sal_ship_tel1,
				sal_bill_tel1,
				sal_ship_tel2,
				sal_bill_tel2,
				sal_ship_fax,
				sal_bill_fax,
				sal_ship_email,
				sal_bill_email,
				sal_prev_docno,
				sal_prev_doctype,
				sal_prev_fycode,
				sal_prev_docdate,
				sal_reference1,
				sal_reference2,
				sal_reference3,
				sal_paytrm_docno,
				sal_deltrm_docno,
				sal_bill_contact_name,
				sal_ship_contact_name,
				sal_shipto_subledger_docno,
				sal_active_status,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_document_status_docno,
				sal_posted_by,
				sal_posted_ts,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_batch_docno,
				sal_tax_percentage,
				sal_tax_amount,
				sal_delivery_date,
				sal_contact_name,
				sal_previous_docno,
				sal_ref1,
				sal_sman_desc,
				sal_mob_no,
				sal_payment_mode_docno,
				sal_estimator,
				sal_chasis_no,
				acmst_desc,
				sublmst_desc,
				sal_wt_amount,
				sal_trailer_no,
				sal_docno sal_prev_docno,
				sal_vat_treatment,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				saldet_vat_percentage,
				saldet_vat_category_docno 
		FROM	#DetailTable6
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno						
		ORDER by	saldet_docsrno
		END

	IF @strDocType IN('SVRS60','SVRS30','SVRS20','SVRS10','SVRS40','SR10','SR20','SR30','SR40','SR60') --For Return
	BEGIN
	PRINT ('Sales return 60')
		SET @strSQLString = N'INSERT INTo #DetailTable
			
			SELECT	SALDET_FYCODE,
					SALDET_DOCTYPE,
					SALDET_DOCNO,
					SALDET_DOCSRNO ,
					SALDET_STOCK_DOCTYPE,
					SALDET_STOCK_DOCNO,		
					CASE WHEN SAL_DOCUMENT_MODE_DOCNO = ''00'' THEN ''Advance Invoice'' 
					WHEN SAL_DOCUMENT_MODE_DOCNO = ''01'' THEN ''Progressive Invoice''
					WHEN SAL_DOCUMENT_MODE_DOCNO = ''91'' THEN ''Final Invoice'' 
					ELSE ''NON STOCK ITEM'' END AS SALDET_STOCK_DESC,
					SALDET_LOCATION_DOCNO,
					1	AS SALDET_QTY,
					''LS'',
					1,
					SALDET_AMOUNT  AS SALDET_AMOUNT,
					SALDET_AMOUNT	AS SALDET_GROSS_AMOUNT,
					0 AS SALDET_DISCOUNT_AMOUNT,
					0 AS SALDET_DISCOUNT_PERCENT,
					SALDET_CAT_REF	AS SALDET_CAT_REF,
					SALDET_DOCDATE,
					SALDET_EXTENDED_DESC,	
					SALDET_REMARKS,
					SALDET_CUSTOMER_REFDESC,
					SALDET_BATCH_DOCNO,
					null,
					SALDET_FYCODE				AS SALDET_PREVIOUS_FYCODE,
					SALDET_DOCTYPE				AS SALDET_PREVIOUS_DOCTYPE,
					SALDET_DOCNO				AS SALDET_PREVIOUS_DOCNO,
					SALDET_DOCSRNO			AS SALDET_PREVIOUS_DOCSRNO,
					0							AS SALDET_AFTER_DOC_QTY,
					0							AS AFTERDOCQTY,
					0							AS RESERVEDQTY,
					0							AS BEFOREQTY,
					acmst_DEsc,
					sublmst_Desc,
					acmst_divn_docno		AS FIXED_DIVISION,
					sal_refno				AS SALDET_REFONENUMBER,
					sal_refdate			AS SALDET_REFONEDATE,
					NUll						AS SALDET_REFTWODATE,
					sal_divn_docno			AS SALDET_DIVN_DOCNO,
					divn_desc				AS SALDET_DIVN_DESC,
					sal_dept_docno			AS SALDET_DEPT_DOCNO,
					dept_desc				AS SALDET_DEPT_DESC,
					Null						AS DOCSTAUS,
					sal_sman_docno		AS SALDET_SMAN_DOCNO,
					sman_Desc				AS SALDET_SMAN_DESC,
					location_master.loc_desc	AS SALDET_LOC_DESC,
					sal_job_docno			AS SALDET_JOB_DOCNO,
					jobmst_desc			AS SALDET_JOBMST_DESC,
					sal_curr_docno		AS SALDET_CURR_DOCNO,
					sal_subledger_docno	AS SALDET_SUBLEDGER_DOCNO,					
					saldet_vat_percentage,
					saldet_vat_category_docno,
					JOBMST_BUDJ_INCOME AS SALDET_CONTRACT_VALUE,
					SAL_DOCUMENT_MODE_DOCNO,
					SALDET_CUR_CUM_INV_PER,
					SALDET_CUR_CUM_INV_AMT,			
					SALDET_PRE_CUM_INV_PER,
					SALDET_PRE_CUM_INV_AMT,
					SALDET_INVOICE_PERCENT,
					SALDET_WORKCOMPLETION_PERCENT,
					SALDET_GROUP_HEADEING1,
					SALDET_GROUP_HEADEING2,
					SALDET_BUDGET_QTY,
					SALDET_BUDGET_RATE,
					SALDET_BUDGET_AMOUNT,
					null
			
			'
SET @strSQLString = @strSQLString + '
			FROM	sales_details 
			INNER JOIN sales_header ON
					saldet_fycode		= sal_fycode AND
					saldet_doctype		= sal_doctype AND
					saldet_docno		= sal_docno 
			INNER JOIN job_master jm2  on
					jm2.jobmst_doctype	= '''+ @strjobdocno +''' AND
					jm2.jobmst_docno	= sal_job_docno 
			LEFT JOIN stock_master STK  ON 
					stk.stkmst_docno		= saldet_stock_docno
			LEFT OUTER JOIN location_master ON
					loc_docno = sal_location_docno 
			LEFT JOIN account_master ON
					acmst_docno				= sal_ac_docno
			LEFT JOIN subledger_master ON
					sublmst_doctype			= sal_ac_docno AND
					sublmst_docno			= ISNULL( sal_subledger_docno,sal_ac_docno) 	
			LEFT OUTER JOIN salesman_master on
					sman_docno				= sal_sman_docno		
			LEFT JOIN division_master Div  ON
					sal_divn_docno			= div.divn_docno 
			LEFT JOIN department_master  Dept  ON
					sal_dept_docno			= Dept.dept_docno 
					##TOLOCATION##
			WHERE	sal_fycode				= ''' + @strFyCode + ''' AND
					sal_docdate				>= ''' + CONVERT(CHAR(10), @dtFmdate, 111) +''' AND
					sal_docdate				< ''' + CONVERT(CHAR(10), @dtTodate, 111) +''' AND
					sal_revised_docno	IS	NULL AND
					ISNULL(sal_document_status_docno,''ACT'') not in (''VOID'',''1002'') AND
					##PREVDOCTYPE##
					##ACDOCNO##
					##SUBLEDGERACDOCNO##
					##PREVDOCNO##
					##POSTEDBY##
					##PREVDOCQTY##
					'

		IF @strPrevDocType is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCTYPE##',  ' sal_doctype='''+ @strPrevDocType + ''' AND ' )
 
		IF @strACCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##ACDOCNO##',  ' sal_ac_docno='''+ @strACCode + ''' AND ' )
 
 		IF @strSubledgerCode is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##SUBLEDGERACDOCNO##',  ' sal_subledger_docno ='''+ @strSubledgerCode + ''' AND ' )

 		IF @strPrevDocNo is null			    
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  '1=1 AND ' )
		Else 
			SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCNO##',  ' sal_docno ='''+ @strPrevDocNo + ''' AND ' )

		--Show only Approved documents
			SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  ' sal_posted_by is NOT NULL AND ' )
		--Else 
		--	SET @strSQLString = REPLACE( @strSQLString, '##POSTEDBY##',  '1=1 AND ' )
		
		SET @strSQLString = REPLACE( @strSQLString, '##PREVDOCQTY##',  ' (saldet_qty - ISNULL( saldet_after_doc_qty,0)) > 0 ' )

		SET @strSQLString = REPLACE( @strSQLString, '##TOLOCATION##',  '' )

		PRINT CAST(@strSQLString as ntext)
		EXEC(@strSQLString  )
			
		SELECT	saldet_docno							AS DocNo,
				saldet_doctype							AS DocType,
				MAX( saldet_docdate)					AS Date,
				MAX( saldet_subledger_docno)			AS PartyCode,
				MAX( sublmst_desc )						AS Party,				 
				saldet_fycode							AS FyCode,
				MAX( saldet_refonenumber)				AS [RefNo],
				MAX( saldet_refonedate)					AS [RefDate],
				MAX( smandesc)	 						AS SalesMan,	
				MAX( saldet_job_docno)					AS JobNo,
				MAX( jobmst_desc)						AS JobDescription,
				MAX( DivnDesc)	 						AS Division,
				MAX( loc_desc) 							AS Location,
				SUM( saldet_amount)						AS Amount,
				MAX( saldet_curr_docno)					AS Currency,
				Null									AS [Make],
				NUll									AS [Model],
				MAX(saldet_cat_ref)						AS [OldDocNo]
		FROM	#DetailTable
	 
		--WHERE ISNULL(saldet_parent_id,0) = 0
		GROUP BY saldet_fycode, saldet_doctype, saldet_docno
  


		SELECT 	 
				#DetailTable.*,
				#detailtable.saldet_fycode	AS [Fycode],
				#detailtable.saldet_doctype	AS [DocType],
				#detailtable.saldet_docno	AS [DocNo],
				sal_ac_docno,
				sal_subledger_docno,
				sales_header.sal_document_mode_docno,
				sal_job_docno,
				sal_document_status_docno,
				sal_ship_street,
				sal_ship_city,
				sal_ship_state,
				sal_ship_zipcode,
				sal_ship_country,
				sal_ship_address,
				sal_location_docno,
				sal_bill_street,
				sal_bill_city,
				sal_bill_state,
				sal_bill_zipcode,
				sal_bill_country,
				sal_bill_address,
				sal_bill_contact_docno,
				sal_bill_contact_name,
				sal_vat_trn,	
				sal_refno,
				sal_refdate,
				sal_cr_days,
				sal_curr_rate,
				sal_net_amount,
				sal_sman_docno,
				sal_curr_docno,
				sal_prev_docno,
				sal_other_amount,
				sal_narration,
			---	sal_docdate,
				sal_discount_percent,
				sal_vat_amount,
				sal_discount_amount,
				sal_gross_amount,
				sal_subledger_docno,
				sal_ref2,
				sal_dept_docno,
				sal_bill_mobile,
				sal_delivery_date,
				sal_paymode_docno,
				sal_paymode_desc,
				sal_deltrm_docno,
				sal_paytrm_desc,
				sal_deltrm_desc,
				sal_paytrm_docno,
				sal_divn_docno,
				sal_ud_label5,
				sal_ud_letter_text,
				sal_ud_label1,
				sal_ud_label4,
				sal_ud_label3,
				sal_ud_label2,
				sal_vat_treatment_docno,
				sal_vat_rate_type,
				sal_vat_treatment,
				sal_posted_by,
				sal_posted_ts ,
				--sal_cont_start_date,
				sal_cont_end_date,
				sal_comments1,
				--sal_service_type_docno,
			
				--sal_rebate_yn,
				--sal_trms_docno,
				sal_sman_desc,
				sal_ud_label9,
				sal_ud_label10,
				sal_order_amount,
				sal_retention_percent,
				sal_retention_amount,
				sal_adv_recovery_percent,
				sal_adv_recovery_amount,
				sal_invoice_amount,
				sal_total_amount,
				sal_net_amount
		FROM	#DetailTable
		INNER JOIN sales_header ON 
				sal_fycode				= saldet_fycode  AND
				sal_doctype				= saldet_doctype  AND
				sal_docno				= saldet_docno	
		--INNER JOIN sales_details sd ON 
		--		#DetailTable.saldet_fycode		= sd.saldet_fycode  AND
		--		#DetailTable.saldet_doctype		= sd.saldet_doctype  AND
		--		#DetailTable.saldet_docno		= sd.saldet_docno	AND
		--		#DetailTable.saldet_docsrno		= sd.saldet_docsrno	
		--INNER JOIN stock_master ON
		--		stkmst_docno	= #DetailTable.SALDET_STOCK_DOCNO	
 	--	INNER JOIN stock_location_master ON
		--		stkloc_doctype = #DetailTable.saldet_stock_doctype AND
		--		stkloc_docno   = #DetailTable.saldet_stock_docno AND
		--		stkloc_loc_docno = #DetailTable.saldet_location_docno		
		ORDER by	saldet_docsrno
		END
GO
