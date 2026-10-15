USE [FACTSERPFIRETECH]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 15-10-2026 : LABDET_NET_OT_HOURS = LABDET_OT_HOURS x 1.5 when the Sunday / LAB_HOLIDAY tick applies, else x 1.25
ALTER PROCEDURE [dbo].[usp_DTS_GridValidate]
	@strXmlRowDetails       nvarchar(max),
    @strCurrentCellName     nvarchar(100),
    @strCurrentCellValue	nvarchar(500),
	@strXmlHeaderFormParam	nvarchar(max) = null,
    @strLoginID             nvarchar(50) 

as

	DECLARE 	@idoc				INT,
				@idoc2				INT,
				@strnormalot		nvarchar(40),
				@strholidayot		nvarchar(40),
				@dtasondate			date,
				@strHolidayFlag		NVARCHAR(20),
				@InTime				numeric(18,3),
				@OutTime			numeric(18,3),
				@NormalHrs			numeric(18,3),
				@lunchhours			numeric(18,3),
				@strHolidayTick		NVARCHAR(20),
				@nOtFactor			NUMERIC(18,3)

	 EXEC sp_xml_preparedocument @idoc output , @strXmlRowDetails  

	 -- Holiday tick from the header form (LAB_HOLIDAY)
	 IF @strXmlHeaderFormParam IS NOT NULL
	 BEGIN
		EXEC sp_xml_preparedocument @idoc2 output , @strXmlHeaderFormParam

		SELECT	@strHolidayTick	=	LAB_HOLIDAY
		FROM	OPENXML(@idoc2, 'FACTS/PARAMETERS',2)
		WITH	( LAB_HOLIDAY NVARCHAR(20) )

		EXEC sp_xml_removedocument @idoc2
	 END

	 SELECT @strnormalot  =  company_desc
	 FROM	company_parameter
	 WHERE  company_code='NORMALOT%'

	 SELECT @strholidayot  =  company_desc
	 FROM	company_parameter
	 WHERE  company_code='HOLIDAYOT%'


	 DECLARE @tbl_CurrenctRow table  
	 (  
		LABDET_FYCODE				NVARCHAR(12),  
		LABDET_DOCTYPE				NVARCHAR(12),  
		LABDET_DOCNO				NVARCHAR(40),  
		LABDET_DOCSRNO				INT,  
		LABDET_IN_TIME				DATETIME,
		LABDET_OUT_TIME				DATETIME,
		LABDET_OT_HOURS				NUMERIC(18,3),
		LABDET_NET_HOURS			NUMERIC(18,3),
		LABDET_NORMAL_HOURS			NUMERIC(18,3),
		LABDET_INC_HOURS			NUMERIC(18,3)  ,
		LABDET_WEEK_OFF				NVARCHAR(40)  ,
		LABDET_DEDUCTION_HOURS		NUMERIC(18,3),
		LABDET_WORK_DATE			DATETIME,
		LABDET_EMP_DOCTYPE			NVARCHAR(12),
		LABDET_NET_OT_HOURS			NUMERIC(18,3)
	 )
  
	 INSERT INTO @tbl_CurrenctRow  
	 (  
		LABDET_FYCODE	,  
		LABDET_DOCTYPE	,  
		LABDET_DOCNO	,  
		LABDET_DOCSRNO	,		
		LABDET_IN_TIME ,       
		LABDET_OUT_TIME,	
		LABDET_OT_HOURS ,
		LABDET_NET_HOURS,
		LABDET_NORMAL_HOURS,
		LABDET_INC_HOURS ,
		LABDET_WEEK_OFF    ,
		LABDET_DEDUCTION_HOURS, 
		LABDET_WORK_DATE,
		LABDET_EMP_DOCTYPE,
		LABDET_NET_OT_HOURS
	 )
	 SELECT *  
	 FROM OPENXML(@idoc, 'FACTS/PARAMETERS',2)  
	 WITH   
	 (     
		LABDET_FYCODE				NVARCHAR(12),  
		LABDET_DOCTYPE				NVARCHAR(12),  
		LABDET_DOCNO				NVARCHAR(40),  
		LABDET_DOCSRNO				INT,  
		LABDET_IN_TIME				DATETIME,
		LABDET_OUT_TIME				DATETIME,
		LABDET_OT_HOURS				NUMERIC(18,3),
		LABDET_NET_HOURS			NUMERIC(18,3),
		LABDET_NORMAL_HOURS			NUMERIC(18,3),
		LABDET_INC_HOURS			NUMERIC(18,3),
		LABDET_WEEK_OFF				NVARCHAR(40)    ,
		LABDET_DEDUCTION_HOURS		NUMERIC(18,3),
		LABDET_WORK_DATE			DATETIME,
		LABDET_EMP_DOCTYPE			NVARCHAR(12),
		LABDET_NET_OT_HOURS			NUMERIC(18,3)
	 )  w

	 EXEC sp_xml_removedocument @idoc
-----------------------------

    SELECT @dtasondate = CAST(labdet_work_date AS DATE)
    FROM	@tbl_CurrenctRow

	PRINT @dtasondate

	SELECT @lunchhours = 1

	SELECT @NormalHrs  = CASE WHEN desig_desc LIKE '%driver%' THEN 10 ELSE 9 END 
	FROM	@tbl_CurrenctRow yy
	INNER JOIN labour_details xx on
			yy.labdet_fycode	=	xx.labdet_fycode	AND	
			yy.labdet_doctype	=	xx.labdet_doctype	AND
			yy.labdet_docno		=	xx.labdet_docno		AND
			yy.labdet_docsrno	=	xx.labdet_docsrno
	INNER JOIN employee_master ON
			empmst_docno = labdet_emp_docno	
	INNER JOIN pay_designation_master ON
			desig_docno = empmst_desg_docno

	PRINT @NormalHrs
	PRINT @lunchhours

	SELECT @NormalHrs  = 0
	FROM   holiday_master
	INNER JOIN @tbl_CurrenctRow ON
      CONVERT(NVARCHAR(10),holmst_date,120)  =	CONVERT(NVARCHAR(10),LABDET_WORK_DATE ,120)

	SELECT @strHolidayFlag  = 'TRUE'
	FROM   HOLIDAY_MASTER
	INNER JOIN @tbl_CurrenctRow ON
      CONVERT(NVARCHAR(10),HOLMST_DATE,120)  =	CONVERT(NVARCHAR(10),LABDET_WORK_DATE ,120)

	PRINT @strholidayot

	UPDATE @tbl_CurrenctRow  		
	SET   LABDET_EMP_DOCTYPE			=	 'EMP'

	--UPDATE @tbl_CurrenctRow  		
	--SET   labdet_normal_hours			=	 @NormalHrs

	--UPDATE @tbl_CurrenctRow  		
	--SET   labdet_ot_hours				=	  ((DATEDIFF(HOUR,labdet_in_time,labdet_out_time) - isnull(labdet_deduction_hours,0) - labdet_normal_hours + isnull(labdet_inc_hours,0)))

	-- Net OT hours: Sunday or Holiday tick -> OT x 1.5, otherwise OT x 1.25
	-- (1900-01-07 was a Sunday, so this does not depend on DATEFIRST / language settings)
	UPDATE @tbl_CurrenctRow  
	SET   labdet_net_ot_hours			=	ISNULL(labdet_ot_hours,0) *
										CASE	WHEN ISNULL(@strHolidayTick,'0') IN ('1','TRUE','Y','YES')
												OR	( labdet_work_date IS NOT NULL
													  AND DATEDIFF(DAY,'19000107',CAST(labdet_work_date AS DATE)) % 7 = 0 )
												THEN 1.5
												ELSE 1.25
										END

	SELECT * FROM @tbl_CurrenctRow
GO
