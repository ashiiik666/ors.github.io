USE [FactsERPGC]
GO
/****** Object:  StoredProcedure [dbo].[usp_Recalculate_MovingAverageCost]    Script Date: 02-10-2026 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--PLEASE NOTE THESE STRETCHES FOR GC AS MARKED
------------------------------------------------------
 -----------BEWARE OF BELOW STRETCH----------------
 ------------------------------------------------------


/*

usp_Recalculate_MovingAverageCost
'GC-SHF-6000',
'GC-SHF-6000',
'2026-01-01',
'2026-09-10'


*/

ALTER PROCEDURE [dbo].[usp_Recalculate_MovingAverageCost]

			@strFmStockCode						VARCHAR( 20) = NULL,
			@strToStockCode						VARCHAR( 20) = NULL,
			@strFmDate							VARCHAR( 30) = Null,
			@strToDate							VARCHAR( 30) = Null
AS

DECLARE		@stock_DocNo						VARCHAR( 20),
			@Divn_docno							VARCHAR( 20),
			@Dept_docno							VARCHAR( 20),
			@location_DocNo						VARCHAR( 6),
			@source_doctype						VARCHAR( 6),
			@fycode								VARCHAR( 6),
			@doctype							VARCHAR( 6),
			@docno								VARCHAR( 10),
			@docsrno							INT,
			@docdate							DATETIME,
			@qty								NUMERIC( 19, 3),
			@rate								NUMERIC( 19, 3),
			@fcrate								NUMERIC( 19, 3),
			@amount								NUMERIC( 19, 3),
			@fcamount							NUMERIC( 19, 3),
			@additional_amount					NUMERIC( 19, 3),
			@costing							TINYINT

CREATE TABLE #tmpsttrn
(
			tsttrn_fycode						VARCHAR( 6) NOT NULL,
			tsttrn_doctype						VARCHAR( 6) NOT NULL,
			tsttrn_docno						VARCHAR( 10) NOT NULL,
			tsttrn_docsrno						INT NOT NULL,
			tsttrn_docdate						DATETIME,
			tsttrn_cost_rate					NUMERIC( 19,3),
			tsttrn_cost_value					NUMERIC( 19,3)
 )

DECLARE
			@dblClsQty							NUMERIC( 19, 3),
			@dblMovingAvgRate					FLOAT( 53),
			@dblThisDocumentCostRate			NUMERIC(19, 3),
			@dblThisDocumentCostValue			NUMERIC(19, 3),
			@strStockDocNo						VARCHAR(30),
			@strLocationCode					VARCHAR( 6),
			@strDivn_docno						VARCHAR( 20),
			@strDept_docno						VARCHAR( 20)

 SET		@strFmStockCode						= NULLIF( @strFmStockCode, '')
 SET		@strToStockCode						= NULLIF( @strToStockCode, '')

 CREATE TABLE #stock_transaction_mvgavg
(
			sttrn_fycode						VARCHAR( 6) NOT NULL,
			sttrn_doctype						VARCHAR( 10) NOT NULL,
			sttrn_docno							VARCHAR( 20) NOT NULL,
			sttrn_docsrno						INT NOT NULL,
			sttrn_docdate						DATETIME,
			sttrn_divn_docno					VARCHAR( 10),
			sttrn_dept_docno					VARCHAR( 10),
			sttrn_stock_docno					VARCHAR( 30),
			sttrn_location_docno				VARCHAR( 6),
			sttrn_qty							NUMERIC( 18,3),
			sttrn_source_doctype				VARCHAR( 6),
			sttrn_rate							NUMERIC( 18,3),
			sttrn_amount						NUMERIC( 18,3),
			sttrn_cost_rate						NUMERIC( 18,3),
			sttrn_cost_Value					NUMERIC( 18,3),
			sttrn_take_for_costing				INT,
			sttrn_SrNo							INT IDENTITY(1,1),
			sttrn_costing_SrNo					INT
)

--CREATE CLUSTERED INDEX IDX_C_Stock_docno ON #stock_transaction_mvgavg(sttrn_stock_docno)
CREATE INDEX IDX_stock_Docno ON #stock_transaction_mvgavg(sttrn_stock_docno)

ALTER TABLE #stock_transaction_mvgavg ADD CONSTRAINT PK_1 PRIMARY KEY CLUSTERED (sttrn_fycode, sttrn_doctype, sttrn_docno, sttrn_docsrno)
ALTER TABLE #tmpsttrn ADD CONSTRAINT PK_2 PRIMARY KEY CLUSTERED (tsttrn_fycode, tsttrn_doctype, tsttrn_docno, tsttrn_docsrno)

--SET @strFmDate = '2025-01-01'

IF @strFmDate IS NULL
BEGIN
	SELECT	@strFmDate = company_Desc FROM company_parameter WHERE company_code='COGS_BATCH_POST_DATE'
	IF 	@strFmDate  IS NULL
		SET @strFmDate = '1999-01-01'
		SET	@strFmDate = DATEADD(d,1, @strFmDate)
END


IF @strToDate IS NULL
	SELECT @strToDate = CONVERT(CHAR(10), Dateadd(d,1, GETDATE()), 120)

UPDATE	stock_transaction
SEt		sttrn_divn_docno = loc_divn_docno
FROM	location_master
WHERE	sttrn_location_docno = loc_docno AND
		sttrn_divn_docno IS NULL

IF @strFmStockCode IS NULL
BEGIN
	INSERT #stock_transaction_mvgavg
	(
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			sttrn_qty,
			sttrn_source_doctype,
			sttrn_rate,
			sttrn_amount,
			sttrn_cost_rate,
			sttrn_cost_Value,
			sttrn_take_for_costing
	)
	SELECT
			MAX( sttrn_fycode),
			'SOP',
			CONVERT(CHAR(10), @strFmDate, 112),
			500+ROW_NUMBER() OVER(ORDER BY sttrn_divn_docno, sttrn_dept_docno, sttrn_stock_docno, sttrn_location_docno),
			@strFmDate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			SUM( sttrn_qty),
			'SOP',
			SUM( sttrn_cost_value)/SUM( sttrn_qty),
			SUM( sttrn_cost_value),
			0,
			0,
			1	AS TakeForCosting
	FROM 	stock_transaction st
	INNER JOIN location_master ON
			sttrn_location_docno = loc_docno
	WHERE	sttrn_docdate < @strFmDate
	GROUP BY sttrn_divn_docno, sttrn_dept_docno, sttrn_stock_docno, sttrn_location_docno
	HAVING SUM(sttrn_qty) <> 0

	INSERT #stock_transaction_mvgavg
	(
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			sttrn_qty,
			sttrn_source_doctype,
			sttrn_rate,
			sttrn_amount,
			sttrn_cost_rate,
			sttrn_cost_Value,
			sttrn_take_for_costing
	 )
	SELECT
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			sttrn_qty,
			sttrn_source_doctype,
			sttrn_rate,
			sttrn_amount,
			0,
			0,
			sdm.source_costing				AS TakeForCosting
	FROM 	stock_transaction st
	INNER JOIN source_doc_master sdm ON
			st.sttrn_source_doctype = sdm.source_docno
	INNER JOIN location_master ON
			sttrn_location_docno = loc_docno
	WHERE	sttrn_docdate >= @strFmDate
	ORDER BY st.sttrn_stock_docno,sttrn_divn_docno, CONVERT( CHAR( 8), st.sttrn_docdate, 112),  sdm.source_costing_sequence, 0-sttrn_qty
END
ELSE
BEGIN
	--Opening #stock_transaction_mvgavg
	INSERT 	#stock_transaction_mvgavg
	(
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			sttrn_qty,
			sttrn_source_doctype,
			sttrn_rate,
			sttrn_amount,
			sttrn_cost_rate,
			sttrn_cost_Value,
			sttrn_take_for_costing
	 )
	SELECT
			MAX( sttrn_fycode),
			'SOP',
			CONVERT(CHAR(10), @strFmDate, 112),
			500+ROW_NUMBER() OVER(ORDER BY sttrn_divn_docno, sttrn_dept_docno, sttrn_stock_docno, sttrn_location_docno),
			@strFmDate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			SUM( sttrn_qty),
			'SOP',
			SUM( sttrn_cost_Value)/SUM( sttrn_qty),
			SUM( sttrn_cost_Value),
			0,
			0,
			1	AS TakeForCosting
	FROM 	stock_transaction st
	INNER JOIN location_master ON
			sttrn_location_docno = loc_docno
	WHERE	sttrn_docdate < @strFmDate AND
			sttrn_stock_docno BETWEEN @strFmStockCode AND @strToStockCode
	GROUP BY sttrn_divn_docno, sttrn_dept_docno, sttrn_stock_docno, sttrn_location_docno
	HAVING SUM(sttrn_qty) <> 0

	INSERT #stock_transaction_mvgavg
	(
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			sttrn_qty,
			sttrn_source_doctype,
			sttrn_rate,
			sttrn_amount,
			sttrn_cost_rate,
			sttrn_cost_Value,
			sttrn_take_for_costing
	 )
	SELECT
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_stock_docno,
			sttrn_location_docno,
			sttrn_qty,
			sttrn_source_doctype,
			sttrn_rate,
			sttrn_amount,
			0,
			0,
			sdm.source_costing				AS TakeForCosting
	FROM 	stock_transaction st
	INNER JOIN source_doc_master sdm ON
			st.sttrn_source_doctype = sdm.source_docno
	INNER JOIN location_master ON
			sttrn_location_docno = loc_docno
	WHERE	sttrn_docdate >= @strFmDate AND
			sttrn_stock_docno BETWEEN @strFmStockCode AND @strToStockCode
	ORDER BY st.sttrn_stock_docno, sttrn_divn_docno, CONVERT( CHAR( 8), st.sttrn_docdate, 112),  sdm.source_costing_sequence, 0-sttrn_qty
END


UPDATE		#stock_transaction_mvgavg
SET			sttrn_costing_SrNo = aa.newSrNo
FROM		(SELECT  sttrn_srno		SrNo,
					ROW_NUMBER()  OVER( ORDER BY  sttrn_stock_docno, sttrn_divn_docno,sttrn_srno ) AS newSrNo
			FROM	#stock_transaction_mvgavg
			) aa
WHERE aa.SrNo = sttrn_srno

UPDATE		#stock_transaction_mvgavg
SET 		sttrn_source_doctype	= 'SAL',
			sttrn_take_for_costing	= 0
WHERE		sttrn_source_doctype	IN('PUR') AND
			sttrn_qty				< 0


-- Sales returns of pre-2026 sales: bring them in at the original issue cost.
-- sttrn_amount MUST be set here too: the costing cursor reads sttrn_amount
-- (not sttrn_cost_rate) for take_for_costing = 1 rows. Without it the return
-- enters the moving average at its selling price (e.g. 23.000 instead of the
-- 22.500 cost), and since the row is relabelled 'PUR' here, the later
-- "SAL/TSF -> PUR, amount = cost_value" step never corrects it.
UPDATE	#stock_transaction_mvgavg
SET     sttrn_cost_rate		= aa.RetCostRate,
		sttrn_cost_Value	= aa.RetCostRate * sttrn_qty ,
		sttrn_amount		= aa.RetCostRate * sttrn_qty ,
		sttrn_source_doctype	= 'PUR',
		sttrn_take_for_costing	= 1
FROM   (SELECT
                ff.sttrn_fycode             AS RETFycode,
                ff.sttrn_doctype            AS RETDocType,
                ff.sttrn_docno              AS RETDocno,
                ff.sttrn_docsrno            AS RETDocSrno,
				zz.sttrn_cost_rate			AS RetCostRate
		FROM	#stock_transaction_mvgavg FF
		INNER JOIN sales_details sr ON
				saldet_fycode				= sttrn_fycode AND
				saldet_doctype				= sttrn_doctype AND
				saldet_docno				= sttrn_docno AND
				saldet_docsrno				= CASE WHEN CEILING(FF.sttrn_docsrno  /1000)  = 0 THEN FF.sttrn_docsrno ELSE CEILING(FF.sttrn_docsrno  /1000) END
		INNER JOIN sales_details srr ON
				srr.saldet_fycode			= sr.saldet_previous_fycode AND
				srr.saldet_doctype			= sr.saldet_previous_doctype AND
				srr.saldet_docno			= sr.saldet_previous_docno AND
				srr.saldet_docsrno			= sr.saldet_previous_docsrno
		INNER JOIN sales_details si ON
				si.saldet_fycode			= srr.saldet_previous_fycode AND
				si.saldet_doctype			= srr.saldet_previous_doctype AND
				si.saldet_docno				= srr.saldet_previous_docno AND
				si.saldet_docsrno			= srr.saldet_previous_docsrno
		INNER JOIN stock_transaction ZZ ON
				si.saldet_previous_fycode	= zz.sttrn_fycode AND
				si.saldet_previous_doctype	= zz.sttrn_doctype AND
				si.saldet_previous_docno	= zz.sttrn_docno AND
				si.saldet_previous_docsrno	= CASE WHEN CEILING(zz.sttrn_docsrno  /1000)  = 0 THEN zz.sttrn_docsrno ELSE CEILING(zz.sttrn_docsrno  /1000) END
		WHERE   FF.sttrn_source_doctype		= 'SAL' AND
				ZZ.sttrn_docdate	<	'2026-01-01'	and
				FF.sttrn_qty > 0) aa
WHERE	aa.RETFycode	= sttrn_fycode AND
		aa.RETDocType 	= sttrn_doctype AND
		aa.RETDocno		= sttrn_docno AND
		aa.RETDocSrno  	= sttrn_docsrno

DECLARE sc_cursor CURSOR FORWARD_ONLY STATIC FOR
	SELECT
			sttrn_stock_docno,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_location_docno,
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_qty,
			sttrn_rate,
			sttrn_amount,
			sttrn_take_for_costing				AS TakeForCosting
	FROM 	#stock_transaction_mvgavg st
	ORDER BY sttrn_costing_SrNo
OPEN sc_cursor
FETCH NEXT FROM sc_cursor INTO
	  @stock_DocNo, @Divn_docno,@Dept_Docno, @location_DocNo,
	  @fycode, @doctype, @docno, @docsrno,
	  @docdate, @qty, @rate, @amount, @costing

SET @dblMovingAvgRate	= 0
SET @dblClsQty			= 0
SET @strStockDocNo		= @stock_DocNo
SET @strLocationCode	= @location_DocNo
SET @strDivn_docno		= @Divn_docno
SET @strdept_docno		= @dept_docno


WHILE (@@FETCH_STATUS =0)
BEGIN
	SET @dblClsQty = @dblClsQty + @qty

	IF @costing = 1
		BEGIN
			-- Transactions like "PUR", "IMP", "PRT", "ADJ", "OPN", "MAN", "LPO", "IRT" etc.
			-- Following IF is for finding the Cost Rate with Additional Amount!
			SET @dblThisDocumentCostValue = @amount

			IF @qty = 0
				SET @dblThisDocumentCostRate = @Rate
			ELSE
				SET @dblThisDocumentCostRate = @dblThisDocumentCostValue / @qty

			-- Core of Moving Average Calculation!
			-- Running totals (Value and Quantity) are calculated, and new rate is fixed if
			-- Running totals are not Zeros!
			IF @dblClsQty = 0
				SET @dblMovingAvgRate  = 0
			ELSE

		   		SET @dblMovingAvgRate = (((@dblClsQty - @qty) * @dblMovingAvgRate) + @dblThisDocumentCostValue) / @dblClsQty

		 END

	 ELSE
		 BEGIN
			SET @dblThisDocumentCostRate	= @dblMovingAvgRate
			SET @dblThisDocumentCostValue	= @dblMovingAvgRate * @qty
		 END

--	Added by Benoy
--	If the Moving Average Rate is -ive
	IF @dblMovingAvgRate < 0
	BEGIN
			SET @dblMovingAvgRate = 0
	END

	INSERT INTO #tmpsttrn
	(
		tsttrn_fycode,
		tsttrn_doctype,
		tsttrn_docno,
		tsttrn_docsrno,
		tsttrn_docdate,
		tsttrn_cost_rate,
		tsttrn_cost_value
	)
	VALUES
	(
		@fycode,
		@doctype,
		@docno,
		@docsrno,
		@docdate,
		@dblThisDocumentCostRate,
		@dblThisDocumentCostValue
	)
	FETCH NEXT FROM sc_cursor INTO
	@stock_DocNo, @Divn_docno,@Dept_Docno, @location_DocNo,
	@fycode, @doctype, @docno, @docsrno,
	@docdate, @qty, @rate, @amount, @costing

	IF @@FETCH_STATUS <> 0 OR @strStockDocNo <> @stock_DocNo OR @strDivn_docno <> @Divn_docno -- OR @strLocationcode <> @location_DocNo
	BEGIN
		  -- Scrolling thru a Different Item or another location!
		  -- Values are re-initialised!
		SET @dblMovingAvgRate		= 0
		SET @dblClsQty			= 0
		SET @strStockDocNo		= @stock_DocNo
		SET @strLocationCode	= @location_DocNo
		SET @strDivn_docno		= @Divn_docno
		SET @strdept_docno		= @dept_docno

	END
END
CLOSE sc_cursor
DEALLOCATE sc_cursor

		SELECT * FROM #tmpsttrn

--select * from #tmpsttrn
--order by tsttrn_docdate asc

--return

--SELECT STTRN_COST_RATE,STTRN_COST_VALUE,* FROM #stock_transaction_mvgavg WHERE STTRN_STOCK_DOCNO = 'GC-SHF-6000'

UPDATE 	#stock_transaction_mvgavg
SET  	sttrn_cost_rate		= tsttrn_cost_rate,
   		sttrn_cost_Value	= tsttrn_cost_value
FROM 	#tmpsttrn
WHERE 	tsttrn_fycode	= sttrn_fycode AND
  		tsttrn_doctype	= sttrn_doctype AND
  		tsttrn_docno	= sttrn_docno AND
  		tsttrn_docsrno	= sttrn_docsrno
----------------------------------------------------------------------------------------------


--SELECT STTRN_COST_RATE,STTRN_COST_VALUE,* FROM #stock_transaction_mvgavg WHERE STTRN_STOCK_DOCNO = 'GC-SHF-6000'

--SELECT * FROM #stock_transaction_mvgavg WHERE sttrn_doctype = 'PDV4'

--Sales Return Cost updation

UPDATE	#stock_transaction_mvgavg
SET     sttrn_cost_rate		= aa.RetCostRate,
		sttrn_cost_Value	= aa.RetCostRate * sttrn_qty
FROM   (SELECT
                ff.sttrn_fycode             AS RETFycode,
                ff.sttrn_doctype            AS RETDocType,
                ff.sttrn_docno              AS RETDocno,
                ff.sttrn_docsrno            AS RETDocSrno,
				zz.sttrn_cost_rate			AS RetCostRate
		FROM	#stock_transaction_mvgavg FF
		INNER JOIN sales_details sr ON
				saldet_fycode				= sttrn_fycode AND
				saldet_doctype				= sttrn_doctype AND
				saldet_docno				= sttrn_docno AND
				saldet_docsrno				= CASE WHEN CEILING(FF.sttrn_docsrno  /1000)  = 0 THEN FF.sttrn_docsrno ELSE CEILING(FF.sttrn_docsrno  /1000) END
		INNER JOIN sales_details srr ON
				srr.saldet_fycode			= sr.saldet_previous_fycode AND
				srr.saldet_doctype			= sr.saldet_previous_doctype AND
				srr.saldet_docno			= sr.saldet_previous_docno AND
				srr.saldet_docsrno			= sr.saldet_previous_docsrno
		INNER JOIN sales_details si ON
				si.saldet_fycode			= srr.saldet_previous_fycode AND
				si.saldet_doctype			= srr.saldet_previous_doctype AND
				si.saldet_docno				= srr.saldet_previous_docno AND
				si.saldet_docsrno			= srr.saldet_previous_docsrno
		INNER JOIN stock_transaction ZZ ON
				si.saldet_previous_fycode	= zz.sttrn_fycode AND
				si.saldet_previous_doctype	= zz.sttrn_doctype AND
				si.saldet_previous_docno	= zz.sttrn_docno AND
				si.saldet_previous_docsrno	= CASE WHEN CEILING(zz.sttrn_docsrno  /1000)  = 0 THEN zz.sttrn_docsrno ELSE CEILING(zz.sttrn_docsrno  /1000) END
		WHERE   FF.sttrn_source_doctype		= 'SAL' AND
				FF.sttrn_qty > 0) aa
WHERE	aa.RETFycode	= sttrn_fycode AND
		aa.RETDocType 	= sttrn_doctype AND
		aa.RETDocno		= sttrn_docno AND
		aa.RETDocSrno  	= sttrn_docsrno

UPDATE	#stock_transaction_mvgavg
SET     sttrn_cost_rate		= aa.RetCostRate,
		sttrn_cost_Value	= aa.RetCostRate * sttrn_qty
FROM   (SELECT
                ff.sttrn_fycode             AS RETFycode,
                ff.sttrn_doctype            AS RETDocType,
                ff.sttrn_docno              AS RETDocno,
                ff.sttrn_docsrno            AS RETDocSrno,
				zz.sttrn_cost_rate			AS RetCostRate
		FROM	#stock_transaction_mvgavg FF
		INNER JOIN sales_details sr ON
				saldet_fycode				= sttrn_fycode AND
				saldet_doctype				= sttrn_doctype AND
				saldet_docno				= sttrn_docno AND
				saldet_docsrno				= CASE WHEN CEILING(FF.sttrn_docsrno  /1000)  = 0 THEN FF.sttrn_docsrno ELSE CEILING(FF.sttrn_docsrno  /1000) END
		INNER JOIN sales_details srr ON
				srr.saldet_fycode			= sr.saldet_previous_fycode AND
				srr.saldet_doctype			= sr.saldet_previous_doctype AND
				srr.saldet_docno			= sr.saldet_previous_docno AND
				srr.saldet_docsrno			= sr.saldet_previous_docsrno
		INNER JOIN sales_details si ON
				si.saldet_fycode			= srr.saldet_previous_fycode AND
				si.saldet_doctype			= srr.saldet_previous_doctype AND
				si.saldet_docno				= srr.saldet_previous_docno AND
				si.saldet_docsrno			= srr.saldet_previous_docsrno
		INNER JOIN #stock_transaction_mvgavg ZZ ON
				si.saldet_previous_fycode	= zz.sttrn_fycode AND
				si.saldet_previous_doctype	= zz.sttrn_doctype AND
				si.saldet_previous_docno	= zz.sttrn_docno AND
				si.saldet_previous_docsrno	= CASE WHEN CEILING(zz.sttrn_docsrno  /1000)  = 0 THEN zz.sttrn_docsrno ELSE CEILING(zz.sttrn_docsrno  /1000) END
		WHERE   FF.sttrn_source_doctype		= 'SAL' AND
				FF.sttrn_qty > 0) aa
WHERE	aa.RETFycode	= sttrn_fycode AND
		aa.RETDocType 	= sttrn_doctype AND
		aa.RETDocno		= sttrn_docno AND
		aa.RETDocSrno  	= sttrn_docsrno

--Transfer Cost Updation
UPDATE 	#stock_transaction_mvgavg
SET 	sttrn_cost_rate 	=		aa.UpCost,
		sttrn_cost_Value 	=		aa.UpCost *  sttrn_qty
FROM	(
		SELECT 		sttrn_fycode									AS UpFycode,
					sttrn_doctype									AS UPDocType,
					sttrn_docno										AS UpDocno,
					sttrn_docsrno + 1								AS UpDocSrno,
					SUM (sttrn_cost_Value) / SUM(sttrn_qty) 		AS UpCost
		FROM		#stock_transaction_mvgavg
		WHERE 		sttrn_doctype IN ('TSF','STV') AND
					sttrn_qty < 0
		GROUP BY 	sttrn_fycode,
					sttrn_doctype,
					sttrn_docno,
					sttrn_docsrno + 1) AA
WHERE 	sttrn_fycode		=  aa.UpFycode AND
		sttrn_doctype		=  aa.UPDocType AND
		sttrn_docno			=  aa.UpDocno AND
		sttrn_docsrno		=  aa.UpDocSrno AND
		sttrn_qty > 0

UPDATE 	#stock_transaction_mvgavg
SET 	sttrn_cost_rate 	=	aa.UpCost,
		sttrn_cost_Value 	=	aa.UpCost *  sttrn_qty
FROM	(
		SELECT 		sttrn_fycode									AS UpFycode,
					sttrn_doctype									AS UPDocType,
					sttrn_docno										AS UpDocno,
					SUM (sttrn_cost_Value) / SUM(sttrn_qty) 		AS UpCost
		FROM		#stock_transaction_mvgavg
		WHERE 		sttrn_source_doctype = 'ISS' AND
					sttrn_qty < 0
		GROUP BY 	sttrn_fycode,
					sttrn_doctype,
					sttrn_docno
		) AA
WHERE 	sttrn_fycode		=  aa.UpFycode AND
		sttrn_doctype		=  aa.UPDocType AND
		sttrn_docno			=  aa.UpDocno AND
		sttrn_qty > 0




UPDATE		#stock_transaction_mvgavg
SET 		sttrn_source_doctype	= 'PUR',
			sttrn_take_for_costing	= 1,
			sttrn_amount			= sttrn_cost_Value
WHERE		sttrn_source_doctype	IN('SAL', 'TSF') AND
			sttrn_qty				> 0

			--BEWARE OF BELOW STRETCH
---------------------------------------------
---------------------------------------------
---------------------------------------------

UPDATE	#stock_transaction_mvgavg
SET		STTRN_COST_RATE	 =	[SPL_AMOUNT2],
		STTRN_COST_VALUE =	[SPL_AMOUNT2] * STTRN_QTY
FROM	[UPDATE_STOCK_TRANSACTION_28_09_2026]
WHERE	STTRN_STOCK_DOCNO = [SPL_STOCK_CODE] AND STTRN_QTY > 0.00

UPDATE	#stock_transaction_mvgavg
SET		STTRN_COST_RATE	 =	[Per Unit Rate],
		STTRN_COST_VALUE =	[Per Unit Rate] * STTRN_QTY
FROM	[4A_AND_4D]
WHERE	STTRN_STOCK_DOCNO = [Code] AND STTRN_DOCTYPE IN ('4D','4A') AND CAST(STTRN_DOCDATE AS DATE) < '2026-01-01'

UPDATE	#stock_transaction_mvgavg
SET		STTRN_COST_RATE	 =	[Per Unit Rate],
		STTRN_COST_VALUE =	[Per Unit Rate] * STTRN_QTY
FROM	[4F_AND_4E]
WHERE	STTRN_STOCK_DOCNO = [Code] AND STTRN_DOCTYPE IN ('4F','4E') AND CAST(STTRN_DOCDATE AS DATE) < '2026-01-01'

UPDATE	#stock_transaction_mvgavg
SET		STTRN_COST_RATE	 =	[Per Unit Rate],
		STTRN_COST_VALUE =	[Per Unit Rate] * STTRN_QTY
FROM	[4F_AND_4E]
WHERE	STTRN_STOCK_DOCNO = [Code] AND STTRN_DOCTYPE IN ('4K','4T','4V') AND CAST(STTRN_DOCDATE AS DATE) < '2026-01-01'

---------------------------------------------
---------------------------------------------
---------------------------------------------




SET			@dblThisDocumentCostRate	= 0
SET			@dblThisDocumentCostValue	= 0
SET			@qty						= 0

DELETE FROm #tmpsttrn

DECLARE sc_cursor CURSOR FORWARD_ONLY STATIC FOR
	SELECT
			sttrn_stock_docno,
			sttrn_divn_docno,
			sttrn_dept_docno,
			sttrn_location_docno,
			sttrn_fycode,
			sttrn_doctype,
			sttrn_docno,
			sttrn_docsrno,
			sttrn_docdate,
			sttrn_qty,
			sttrn_rate,
			sttrn_amount,
			sttrn_take_for_costing				AS TakeForCosting
	FROM 	#stock_transaction_mvgavg st
	ORDER BY sttrn_costing_SrNo
OPEN sc_cursor
FETCH NEXT FROM sc_cursor INTO
	  @stock_DocNo, @Divn_docno, @Dept_Docno, @location_DocNo,
	  @fycode, @doctype, @docno, @docsrno,
	  @docdate, @qty, @rate, @amount, @costing

SET @dblMovingAvgRate	= 0
SET @dblClsQty			= 0
SET @strStockDocNo		= @stock_DocNo
SET @strLocationCode	= @location_DocNo
SET @strDivn_docno		= @Divn_docno
SET @strdept_docno		= @dept_docno

WHILE (@@FETCH_STATUS =0)
BEGIN
	SET @dblClsQty = @dblClsQty + @qty
	IF @costing = 1
		BEGIN
			-- Transactions like "PUR", "IMP", "PRT", "ADJ", "OPN", "MAN", "LPO", "IRT" etc.
			-- Following IF is for finding the Cost Rate with Additional Amount!
			SET @dblThisDocumentCostValue = @amount

			IF @qty = 0
				SET @dblThisDocumentCostRate = @Rate
			ELSE
				SET @dblThisDocumentCostRate = @dblThisDocumentCostValue / @qty

			-- Core of Moving Average Calculation!
			-- Running totals (Value and Quantity) are calculated, and new rate is fixed if
			-- Running totals are not Zeros!
			IF @dblClsQty = 0
				SET @dblMovingAvgRate  = 0
			ELSE
		   		SET @dblMovingAvgRate = (((@dblClsQty - @qty) * @dblMovingAvgRate) + @dblThisDocumentCostValue) / @dblClsQty
		 END
	 ELSE
		 BEGIN
			SET @dblThisDocumentCostRate = @dblMovingAvgRate
			SET @dblThisDocumentCostValue = @dblMovingAvgRate * @qty
		 END

	IF @dblMovingAvgRate < 0
			SET @dblMovingAvgRate = 0

	INSERT INTO #tmpsttrn
		(
			tsttrn_fycode,
			tsttrn_doctype,
			tsttrn_docno,
			tsttrn_docsrno,
			tsttrn_docdate,
			tsttrn_cost_rate,
			tsttrn_cost_value
		)
	VALUES
		(
			@fycode,
			@doctype,
			@docno,
			@docsrno,
			@docdate,
			@dblThisDocumentCostRate,
			@dblThisDocumentCostValue
		)

--SELECT * FROM #tmpsttrn

	FETCH NEXT FROM sc_cursor INTO
	@stock_DocNo, @Divn_docno,@Dept_Docno, @location_DocNo,
	@fycode, @doctype, @docno, @docsrno,
	@docdate, @qty, @rate, @amount, @costing

	IF @@FETCH_STATUS <> 0 OR @strStockDocNo <> @stock_DocNo OR @strDivn_docno <> @Divn_docno  --OR @strLocationcode <> @location_DocNo
	BEGIN
		  -- Scrolling thru a Different Item or another location!
		  -- Values are re-initialised!
		SET @dblMovingAvgRate		= 0
		SET @dblClsQty			= 0
		SET @strStockDocNo		= @stock_DocNo
		SET @strLocationCode	= @location_DocNo
		SET @strDivn_docno		= @Divn_docno
		SET @strdept_docno		= @dept_docno
	END
END
CLOSE sc_cursor
DEALLOCATE sc_cursor

 --select * from #stock_transaction_mvgavg
 --where sttrn_stock_docno = 'R10147'
 --ORDER BY  sttrn_docdate

--SELECT	sttrn_cost_rate,
--		sttrn_cost_value,
--		*
--FROM	stock_transaction
--WHERE	sttrn_stock_docno = '10DL1FT80'

--SELECT * FROM #tmpsttrn

UPDATE 	stock_transaction
SET  	sttrn_cost_rate		=	tsttrn_cost_rate,
   		sttrn_cost_value	=	tsttrn_cost_value
FROM 	#tmpsttrn
WHERE 	tsttrn_fycode	= sttrn_fycode		AND
  		tsttrn_doctype	= sttrn_doctype		AND
  		tsttrn_docno	= sttrn_docno		AND
  		tsttrn_docsrno	= sttrn_docsrno		AND
		sttrn_docdate	>= @strFmDate		AND
		sttrn_docdate	< @strToDate		AND
		sttrn_stock_doctype	<>	'SMNS'

		--BEWARE OF BELOW STRETCH
---------------------------------------------
---------------------------------------------
---------------------------------------------

---LAKMAL PROVIDED SHEET

UPDATE	STOCK_TRANSACTION
SET		STTRN_COST_RATE	 =	[SPL_AMOUNT2],
		STTRN_COST_VALUE =	[SPL_AMOUNT2] * STTRN_QTY
FROM	[UPDATE_STOCK_TRANSACTION_28_09_2026]
WHERE	STTRN_STOCK_DOCNO = [SPL_STOCK_CODE]

---LAKMAL PROVIDED SHEET

UPDATE	STOCK_TRANSACTION
SET		STTRN_COST_RATE	 =	[RATE],
		STTRN_COST_VALUE =	[RATE] * STTRN_QTY
FROM	UPDATE_COST_GC
WHERE	STTRN_STOCK_DOCNO = [ITEM]

---------------------------------------------
---------------------------------------------
---------------------------------------------

--select * from [UPDATE_STOCK_TRANSACTION_28_09_2026]


--SELECT	sttrn_cost_rate,
--		sttrn_cost_value,
--		*
--FROM	stock_transaction
--WHERE	sttrn_stock_docno = '10DL1FT80'

ALTER TABLE #stock_transaction_mvgavg DROP CONSTRAINT PK_1
drop table #stock_transaction_mvgavg

--SELECT sttrn_cost_rate,sttrn_cost_value,* FROM stock_transaction WHERE sttrn_doctype = 'PDV4' AND STTRN_STOCK_DOCNO = '55626D80'

/*

UPDATE	STOCK_TRANSACTION
SET		STTRN_COST_RATE	 =	[SPL_AMOUNT2],
		STTRN_COST_VALUE =	[SPL_AMOUNT2] * STTRN_QTY
FROM	[UPDATE_STOCK_TRANSACTION_28_09_2026]
WHERE	STTRN_STOCK_DOCNO = [SPL_STOCK_CODE] AND STTRN_QTY > 0.00


SELECT * FROM [4A_AND_4D]

SELECT * FROM [4F_AND_4E]

SELECT * FROM [4K_4T_AND_4V]

*/
ALTER TABLE #tmpsttrn DROP CONSTRAINT PK_2
drop table #tmpsttrn
RETURN
