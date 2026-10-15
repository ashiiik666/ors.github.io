USE [FactsERPGC]
GO
/****** Object:  StoredProcedure [dbo].[usp_PSV_PhysicalStockComparison_Normal]    Script Date: 15-10-2026 4:05:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
	-- PREVIEW (same call as before)
	exec usp_PSV_PhysicalStockComparison_Normal
			@strFmDate = '2026-09-01', @strToDate = '2026-10-01', @StrPSVNo = '',
			@intShowDifferencesOnly = 1, @intPhysicalStockZero = 0, @intIgnoreDuplicatePhysicalStockTaking = 0,
			@intShowPhysicalStockTakenItemsOnly = 1, @intIgnorePhysicalStockAdjustments = 0,
			@strLocationCode = '', @strStockCode = '', @strVBNewID = '<guid>',
			@strStatus = 'PREVIEW', @strRemarks = '', @strLoginID = 'FACTS'

	-- POST: same call with @strStatus = 'POST'. Optional last parameters:
	--		@strPSVDocTypes = 'PRCPSV'			only these PSV document types (default NULL = all types in psv_details)
	--		@intRepost      = 1					post even if the PSV documents were already adjusted

	CHANGE LOG (14-10-2026)
	-----------------------
	1) PSV document types.  The count query was hard-coded to psvdet_doctype = 'PRCPSV', so every item counted on a
	   PSV10 document (Dec-2025 docs 1001-1004 = 683 items, Sep-2026 doc 1005 = 83 items; none of them is ever on a
	   PRCPSV document) was treated as "system stock, not counted" and was ZEROED when posting.
	   Now all PSV document types are read.  New optional @strPSVDocTypes restricts them ('PRCPSV' = old behaviour).
	2) System qty (option "physical stock taken items only"): removed the "sttrn_batch_docno IS NOT NULL" filter.
	   It made the system qty include only batch-tagged transactions (almost none), so the adjustment came out
	   as the full physical qty.  The EXISTS test now also matches the LOCATION.
	3) "Show differences only" compared single rows.  Physical rows and system rows are separate rows, so an item
	   whose physical qty equals the system qty was never removed.  Now it compares the totals per item + location.
	4) "Ignore physical stock adjustments" (option 5) only filled a table variable that nothing used.  It now removes
	   the adjustment-voucher transactions (type CADJPP, dated inside the period) from the system qty.  Forced OFF when posting.
	5) Posting:
	   - stops with a message if the document type is missing in document_master (before: details were inserted without a header);
	   - stops if PSV lines in the period have no location (they were silently dropped, their items then zeroed);
	   - stops if the PSV documents were already adjusted (double posting) unless @intRepost = 1;
	   - document numbers are given only to documents that really have lines, and lastno_master is moved by exactly
	     that count (before: a document without lines left a gap, the next number then collided);
	   - vouchers, lines and lastno_master are created in one transaction;
	   - after the auto-approval it checks that stock_transaction rows exist for every voucher and raises an error
	     listing the vouchers that were created but not posted (before: failure was silent).
	8) TWO VOUCHERS PER LOCATION (type CADJPP):  voucher 1 = ZEROING voucher: every item with system stock at the location
	   gets a line that brings it to 0 (DOWN for positive stock, UP for negative stock);  voucher 2 = ADJUSTMENT voucher:
	   UP lines with the counted qty.  Both carry the same date (latest count date) and the same moving-average rate taken
	   BEFORE posting.  They are approved one by one, zeroing voucher first.  Items without a moving-average cost take the standard cost.
	   Note: with "show differences only" ticked, items whose count equals the system qty are left out of both vouchers.
	9) POST ignores "physical stock taken items only": the zeroing voucher takes EVERY item that has system stock at the selected
	   locations (before, items that were stock-holding but not counted stayed in stock).  The preview still honours the option.
	6) If no location is selected, all locations are used (before: empty result).
	7) PSV lines are grouped per document type as well, quantity NULL is treated as 0, debug PRINT lines removed,
	   preview SELECT no longer breaks when usp_parameters has an empty fields list / order by.

	CHANGE LOG (15-10-2026)
	-----------------------
	10) Check "PSV lines without a location" (posting) now blocks only when it can do harm: a PSV line without a location
	    is stopped only if its item has system stock at one of the SELECTED locations (that item would be zeroed although it
	    was counted).  Lines without a location whose items have no stock in the selected locations no longer stop the posting.
	    The message lists the documents AND the item codes so the location can be entered on those lines.
*/

ALTER  PROCEDURE [dbo].[usp_PSV_PhysicalStockComparison_Normal]
			@strFmDate            					NVARCHAR(10),
			@strToDate            					NVARCHAR(10),
			@StrPSVNo								NVARCHAR(20),
			@intShowDifferencesOnly          		INT,
			@intPhysicalStockZero					INT,
			@intIgnoreDuplicatePhysicalStockTaking	INT,
			@intShowPhysicalStockTakenItemsOnly		INT,
			@intIgnorePhysicalStockAdjustments		INT,
			@strLocationCode      	     	 		NVARCHAR(100),
			@strStockCode      	     	 			NVARCHAR(100),
			@strVBNewID 	           				NVARCHAR(50),
			@strStatus								NVARCHAR(50),
			@strRemarks								NVARCHAR(250),
			@strLoginID								NVARCHAR(20),
			@strADJDocType							VARCHAR(6) = NULL,
			@strPSVDocTypes							NVARCHAR(200) = NULL,
			@intRepost								INT = 0
AS

	SET NOCOUNT ON

	DECLARE @strSQLString 							NVARCHAR(MAX),
			@strFycode								NVARCHAR(6),
			@strDocTypeFilter						NVARCHAR(600),
			@strIgnoreAdjFilter						NVARCHAR(600),
			@strTakenOnlyFilter						NVARCHAR(600)

	DECLARE @str_join_condition						NVARCHAR(2000),
			@str_fields_list						NVARCHAR(2000),
			@str_from_tables						NVARCHAR(2000),
			@str_order_by							NVARCHAR(2000),
			@str_where_condition					NVARCHAR(2000)

	DECLARE @dtFmDate								DATETIME,
			@dtToDate								DATETIME

	-- The adjustment voucher type used for physical stock posting
	SET		@strADJDocType	= 'CADJPP'

	-- Posting on top of "ignore adjustments" would adjust the stock twice
	-- Posting always zeroes ALL stock of the selected locations (items that were not counted too), so the "counted items only" option is ignored
	IF @strStatus = 'POST'
	BEGIN
		SET @intIgnorePhysicalStockAdjustments = 0
		SET @intShowPhysicalStockTakenItemsOnly = 0
	END

	SET		@dtFmDate = CONVERT(DATETIME,@strFmDate)
	SET		@dtToDate = CONVERT(DATETIME,@strTodate)

	CREATE TABLE #SelectedLoc_Normal
			(
			tmp_LocCode			NVARCHaR(20),
			tmp_Locdesc			NVARCHaR(200),
			tmp_BatchControl	INT
			)

	INSERT INTO #SelectedLoc_Normal
			(
			tmp_LocCode,
			tmp_Locdesc,
			tmp_BatchControl
			)
	SELECT	MMD_DOCNO,
			MMD_DESC,
			0
	FROM	MULTYSELECT_MASTER_DATA
	WHERE	MMD_NEWID	=	@strVBNewID AND
			MMD_DOCTYPE	=	'LOC'

	-- No location selected = all locations
	IF NOT EXISTS (SELECT 1 FROM #SelectedLoc_Normal)
	BEGIN
		INSERT INTO #SelectedLoc_Normal
				(
				tmp_LocCode,
				tmp_Locdesc,
				tmp_BatchControl
				)
		SELECT	loc_docno,
				loc_docno,
				0
		FROM	location_master
	END

	CREATE TABLE #tblTemp
			(
			psvFycode								NVARCHAR(6),
			psvdoctype								NVARCHAR(6),
			psvdocNo								NVARCHAR(20),
			psvdocsrno								INT,
			psvdocdate								DATETIME,
			psvLocation								NVARCHAR(20),
			StockCode								NVARCHAR(20),
			psvUnitCode								NVARCHAR(20),
			BATCHCODE 								NVARCHAR(20),
			PSVDate									DATETIME,
			PSVQty									NUMERIC(19,3) DEFAULT 0,
			SystemQty								NUMERIC(19,3) DEFAULT 0,
			Rate									NUMERIC(19,3) DEFAULT 0,
			Amount									NUMERIC(19,3) DEFAULT 0,
			SrNo									BIGINT IDENTITY,
			PRIMARY KEY(StockCode,psvLocation,SrNo)
			)
			
	CREATE INDEX [IX_Temp_PCS_Table] ON #tblTemp ([StockCode])  ON [PRIMARY]

	SELECT 	@str_join_condition		= ISNULL( usp_join_condition,''),
			@str_fields_list		= usp_fields_list,
			@str_from_tables		= usp_from_tables,
			@str_order_by			= usp_order_by,
			@str_where_condition	= usp_where_condition
	FROM	usp_parameters
	WHERE	usp_newid = @strVBNewID

	SELECT	@strFycode		=	COMPANY_DESC
	FROM	company_parameter
	WHERE	company_code	=	'STRYEARCODE'

	-----PSV DOCUMENT TYPES (NULL / empty = all types)
	IF ISNULL(@strPSVDocTypes, '') = ''
		SET @strDocTypeFilter = ''
	ELSE
		SET @strDocTypeFilter = ' AND CHARINDEX('','' + psvdet_doctype + '','', '',' + REPLACE( REPLACE( @strPSVDocTypes, ' ', ''), '''', '''''') + ','') > 0'

	SET	@strSQLString = '
			SELECT	MAX(psvdet_fycode)				AS	psvdet_fycode,
					psvdet_doctype					AS	psvdet_doctype,
					MAX(psvdet_docno)				AS	psvdet_docno,
					MAX(psvdet_docsrno)				AS	psvdet_docsrno,
					CAST(psvdet_docdate AS DATE)	AS	psvdet_docdate,
					psvdet_location_docno,
					psvdet_stock_docno,
					MAX(STKMST_UNIT_DOCNO)			AS  psvdet_unit_docno,
					NULL,
					CAST(psvdet_docdate AS DATE)	AS	psvdet_docdate,
					SUM(ISNULL(psvdet_qty,0)*ISNULL(stku_from_qty/stku_to_qty,1))	AS	psvdet_qty,
					SUM(psvdet_rate*ISNULL(stku_to_qty/stku_from_qty,1))			AS	psvdet_rate
			FROM	psv_details
			INNER JOIN STOCK_MASTER ON
				STKMST_DOCNO = psvdet_stock_docno
			INNER JOIN #SelectedLoc_Normal	ON
				psvdet_location_docno	=	tmp_LocCode
			LEFT JOIN STOCK_UNIT ON
				STKU_DOCNO		= PSVDET_STOCK_DOCNO AND
				STKU_UNIT_DOCNO = psvdet_unit_docno
			##FACTSMULTIPLEITEM##
			##FACTSMULTIPLELOC##
			##FACTSMULTIPLEDOCNO##
			WHERE	psvdet_docdate >= ''' + @strFmDate + ''' AND
					psvdet_docdate < ''' + @strToDate +'''
					##FACTSDOCTYPE##
			GROUP by  psvdet_doctype, psvdet_stock_docno, psvdet_location_docno, CAST(psvdet_docdate AS DATE)
			ORDER BY  psvdet_stock_docno, psvdet_location_docno, CAST(psvdet_docdate AS DATE), psvdet_doctype'

	-------MULTIPLE ITEM SELECTION CHECKING
	IF ISNULL(@strStockCode, '') = ''
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLEITEM##', '')
	END
	ELSE
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLEITEM##', ' INNER JOIN multyselect_master_data stk ON
																				stk.mmd_newid = ''' + @strVBNewID + ''' AND
																				stk.mmd_docno = psvdet_stock_docno')
	END
	------SELECTED LOCATIONS ONLY
	IF ISNULL(@strLocationCode, '') = ''
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLELOC##','')
	END
	ELSE
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLELOC##',' INNER JOIN multyselect_master_data loc ON
																				loc.mmd_newid = ''' + @strVBNewID + ''' AND
																				loc.mmd_docno = psvdet_location_docno')
	END
	------SELECTED PSV DOCUMENTS ONLY NEED TO CONSIDER?
	IF ISNULL(@StrPSVNo, '') = ''
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLEDOCNO##','')
	END
	ELSE
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLEDOCNO##', ' INNER JOIN multyselect_master_data doc ON
																			doc.mmd_newid	= ''' + @strVBNewID + '''	AND
																			doc.mmd_DOCtYPE = psvdet_doctYPE			AND
																			doc.mmd_docno	= psvdet_docno
																			')
	END
	SET @strSQLString = REPLACE( @strSQLString, '##FACTSDOCTYPE##', @strDocTypeFilter)

	----INSERTING INTO TEMP TABLE
	INSERT INTO #tblTemp
			(
			psvFycode,
			psvdoctype,
			psvdocNo,
			psvdocsrno,
			psvdocdate,
			psvLocation,
			StockCode,
			psvUnitCode,
			BATCHCODE,
			PSVDate,
			PSVQty,
			Rate
			)
	EXEC(@strSQLString)

	SET	@strSQLString	=	''

	----UPDATING IN TEMPORARY TABLE
	UPDATE	#tblTemp
	SET		PSVDate = DOCADTE
	FROM	(
			SELECT MIN(PSVDate)  AS DOCADTE
			FROM #tblTemp
			)AA

	-----TICK NO-4 IGNORE DUPLICATES(NO EFFECT)
	IF @intIgnoreDuplicatePhysicalStockTaking = 1
	BEGIN
		DELETE #tblTemp
		FROM (
			SELECT	StockCode,
					MAX( Srno) AS SrNo,
					psvLocation
			FROM #tblTemp
			GROUP BY StockCode, psvLocation,BATCHCODE
	      )	AS A
		WHERE	#tblTemp.StockCode		= A.StockCode	AND
				#tblTemp.psvLocation	= A.psvLocation AND
				#tblTemp.SrNo			< A.SrNo
	END

	-----SYSTEM QTY FILTERS
	SET @strIgnoreAdjFilter	= ''
	SET @strTakenOnlyFilter	= ''

	------TICK NO-5 IGNORE ADJUSTMENT VOUCHERS: leave out the physical stock adjustments of this period
	IF @intIgnorePhysicalStockAdjustments = 1
		SET @strIgnoreAdjFilter = ' AND NOT (bbb.sttrn_doctype = ''' + @strADJDocType + ''' AND bbb.sttrn_docdate >= ''' + @strFmDate + ''')'

	----TICK N0-2 CONSIDER PHYSICAL STOCK TAKEN ITEMS ONLY (same item AND same location as a counted line)
	IF @intShowPhysicalStockTakenItemsOnly = 1
		SET @strTakenOnlyFilter = ' AND EXISTS (SELECT 1 FROM #tblTemp tt WHERE tt.StockCode = bb.sttrn_stock_docno AND tt.psvLocation = bb.sttrn_location_docno)'

	SET	@strSQLString = 'SELECT	ROW_NUMBER()OVER(ORDER BY  sttrn_stock_docno, sttrn_location_docno),
									sttrn_location_docno,
									sttrn_stock_docno,
									SysQty as SysQty,
									cost_Rate
							FROM	(
									SELECT	sttrn_location_docno,
											sttrn_stock_docno,
											SUM(sttrn_qty)		AS	SysQty,
											MAX(STKMST_STDCOST)	AS	Cost_Rate
									FROM stock_transaction bbb
									INNER JOIN STOCK_MASTER ON
										STTRN_STOCK_DOCNO	=	STKMST_DOCNO
									INNER JOIN #SelectedLoc_Normal	ON
										sttrn_location_docno	=	tmp_LocCode
									##FACTSMULTIPLEITEM##
									##FACTSMULTIPLELOC##
									WHERE 	sttrn_docdate < ''' + @strToDate +'''
											##FACTSIGNOREADJ##
									GROUP BY sttrn_stock_docno, sttrn_location_docno
									)bb
							WHERE	SysQty <> 0
									##FACTSTAKENONLY##'

	SET @strSQLString = REPLACE( @strSQLString, '##FACTSIGNOREADJ##', @strIgnoreAdjFilter)
	SET @strSQLString = REPLACE( @strSQLString, '##FACTSTAKENONLY##', @strTakenOnlyFilter)

	-----STOCK CODE SELECTION
	IF ISNULL(@strStockCode, '') = ''
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLEITEM##', '')
	END
	ELSE
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLEITEM##', ' INNER JOIN multyselect_master_data stk ON
																				stk.mmd_newid = ''' + @strVBNewID + ''' AND
																				STK.MMD_DOCNO = STTRN_STOCK_DOCNO')
	END
	----LOCATION SELECTION
	IF ISNULL(@strLocationCode, '') = ''
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLELOC##', '')
	END
	ELSE
	BEGIN
		SET @strSQLString = REPLACE( @strSQLString, '##FACTSMULTIPLELOC##', ' INNER JOIN multyselect_master_data loc ON
																				loc.mmd_newid = ''' + @strVBNewID + ''' AND
																				loc.mmd_docno = sttrn_location_docno')
	END

	INSERT INTO #tblTemp( psvdocsrno, psvlocation, StockCode,  SystemQty,Rate)
	EXEC(@strSQLString)

	------UPDAtING PSV DOCNO FOR SYSTEM STOCK MANUAL ENTRY LINES
	UPDATE	#tblTemp
	SET		psvdocno = 'PSV' + LTRIM(CONVERT( NVARCHAR(20), CEILING( (psvdocsrno-1)/100)+1)) ,
			psvdocsrno	= ((psvdocsrno-1) % 100)+1 ,
			psvdocTYPE = 'PSV',
			PSVFYCODE = @strfycode
	WHERE	psvdocno IS NULL

	UPDATE	#tblTemp
	SET		psvdocdate = docdate
	FROM	(
			SELECT	MAX(psvdocdate)	AS docdate
			FROM	#tblTemp
			)aa
	WHERE	psvdocdate IS NULL

	-----updating date as TODATE
	UPDATE	#tblTemp
	SET		psvdocdate = @strToDate
	WHERE	psvdocdate IS NULL

	-------TICK-3 SET PSV QTY=SYSTEM QTY
	IF @intPhysicalStockZero = 1
	BEGIN
		UPDATE  #tblTemp SET PSVQty = SystemQty WHERE ISNULL(PSVQty,0) = 0
	END

	-------TICK-1	DELETING IF SYSTEM QTY	=	PHYSICAL QTY  (compared per item + location, not per row)
	IF @intShowDifferencesOnly = 1
	BEGIN
		DELETE	t
		FROM	#tblTemp t
		INNER JOIN
				(
				SELECT	StockCode,
						psvLocation
				FROM	#tblTemp
				GROUP BY StockCode, psvLocation
				HAVING	SUM(ISNULL(PSVQty,0)) = SUM(ISNULL(SystemQty,0))
				) m ON
			m.StockCode		= t.StockCode AND
			m.psvLocation	= t.psvLocation
	END

	------COST = MOVING AVERAGE OF THE ITEM AT THE LOCATION AS ON THE DATE
	UPDATE 	#tblTemp
	SET		Rate = ISNULL( dbo.[fn_MovingAverageCostLocationAsOnDate] (	StockCode,psvdocdate,psvLocation), 0)

	------ITEM WITHOUT ANY MOVING AVERAGE COST (never had stock): fall back to the standard cost of the item
	UPDATE 	t
	SET		Rate = ISNULL( s.STKMST_STDCOST, 0)
	FROM	#tblTemp t
	INNER JOIN stock_master s ON s.stkmst_docno = t.StockCode
	WHERE	ISNULL(t.Rate,0) = 0

	---UPDATING AMOUNT FIELD
	UPDATE 	  	#tblTemp
	SET			Amount = Rate  * (ISNULL( PSVQty,0) - ISNULL(SystemQty,0))

	-----IF POST TO ADJUSTMENT VOUCHER
	-----TWO VOUCHERS PER LOCATION:  1) ZEROING voucher (every item's system qty at the location -> 0)
	-----                           2) ADJUSTMENT voucher (the counted qty is put in)
	IF @strStatus = 'POST'
	BEGIN
		DECLARE		@strBadDocs			NVARCHAR(1000),
					@strBadItems		NVARCHAR(1000),
					@strXmlDocDetails	NVARCHAR(MAX),
					@strCurDocNo		NVARCHAR(20),
					@intDocCount		INT,
					@blnOwnTran			BIT,
					@dtAdjDate			DATETIME

		DECLARE		@tblLines TABLE
					(
					LineId				INT IDENTITY(1,1),
					kind				INT,				----1 = ZEROING LINE, 2 = ADJUSTMENT (COUNT) LINE
					location_code		NVARCHAR(20),
					StockCode			NVARCHAR(20),
					BATCHCODE			NVARCHAR(20),
					Qty					NUMERIC(19,3),		----SIGNED QTY OF THE ADJUSTMENT LINE (+ UP, - DOWN)
					Rate				NUMERIC(19,4),
					prev_doctype		NVARCHAR(20),
					prev_docno			NVARCHAR(20),
					prev_docsrno		INT,
					ADJDocNo			NVARCHAR(20),
					DocSrNo				INT
					)

		DECLARE		@tblDocs TABLE
					(
					seq					INT IDENTITY(1,1),
					ADJDocNo			NVARCHAR(20)
					)

		----CHECK 1: THE ADJUSTMENT DOCUMENT TYPE MUST EXIST
		IF NOT EXISTS (SELECT 1 FROM document_master WHERE dm_docno = @strADJDocType)
		BEGIN
			RAISERROR('Document type %s is not defined in document_master. Nothing was posted.', 16, 1, @strADJDocType)
			RETURN
		END

		----CHECK 2: PSV LINES WITHOUT LOCATION (they are not read, so their items would be treated as not counted and zeroed)
		----         Only a problem when the item has system stock in one of the selected locations: that item would be zeroed although it was counted.
		SET @strBadDocs = ''
		SET @strBadItems = ''
		SELECT	@strBadDocs = @strBadDocs + CASE WHEN @strBadDocs = '' THEN '' ELSE ', ' END + x.docs
		FROM	(
				SELECT	DISTINCT psvdet_doctype + '-' + psvdet_docno AS docs
				FROM	psv_details
				WHERE	psvdet_docdate >= @dtFmDate AND
						psvdet_docdate < @dtToDate AND
						ISNULL(psvdet_qty,0) <> 0 AND
						NULLIF(LTRIM(RTRIM(ISNULL(psvdet_location_docno,''))),'') IS NULL AND
						( ISNULL(@strPSVDocTypes,'') = '' OR
						  CHARINDEX(',' + psvdet_doctype + ',', ',' + REPLACE(@strPSVDocTypes,' ','') + ',') > 0 ) AND
						( ISNULL(@StrPSVNo,'') = '' OR
						  EXISTS (SELECT 1 FROM multyselect_master_data d
								  WHERE d.mmd_newid = @strVBNewID AND d.mmd_doctype = psvdet_doctype AND d.mmd_docno = psvdet_docno) ) AND
						( ISNULL(@strStockCode,'') = '' OR
						  EXISTS (SELECT 1 FROM multyselect_master_data s
								  WHERE s.mmd_newid = @strVBNewID AND s.mmd_docno = psvdet_stock_docno) ) AND
						EXISTS (SELECT	1
								FROM	stock_transaction st
								INNER JOIN #SelectedLoc_Normal sl ON
									sl.tmp_LocCode = st.sttrn_location_docno
								WHERE	st.sttrn_stock_docno = psvdet_stock_docno AND
										st.sttrn_docdate < @dtToDate
								GROUP BY st.sttrn_location_docno
								HAVING	SUM(st.sttrn_qty) <> 0)
				) x
		IF @strBadDocs <> ''
		BEGIN
			SELECT	@strBadItems = @strBadItems + CASE WHEN @strBadItems = '' THEN '' ELSE ', ' END + y.itm
			FROM	(
					SELECT	DISTINCT TOP 15 psvdet_stock_docno AS itm
					FROM	psv_details
					WHERE	psvdet_docdate >= @dtFmDate AND
							psvdet_docdate < @dtToDate AND
							ISNULL(psvdet_qty,0) <> 0 AND
							NULLIF(LTRIM(RTRIM(ISNULL(psvdet_location_docno,''))),'') IS NULL AND
							CHARINDEX(',' + psvdet_doctype + '-' + psvdet_docno + ',', ',' + REPLACE(@strBadDocs,' ','') + ',') > 0
					) y
			SET @strBadDocs = LEFT(@strBadDocs, 400)
			SET @strBadItems = LEFT(@strBadItems, 400)
			RAISERROR('PSV lines without a location exist in this period (documents: %s; items e.g.: %s) and these items have stock in the selected locations, so they would be zeroed although counted. Enter the location on those lines and run again. Nothing was posted.', 16, 1, @strBadDocs, @strBadItems)
			RETURN
		END

		----CHECK 3: PSV DOCUMENTS ALREADY ADJUSTED (double posting)
		IF ISNULL(@intRepost, 0) = 0
		BEGIN
			SET @strBadDocs = ''
			SELECT	@strBadDocs = @strBadDocs + CASE WHEN @strBadDocs = '' THEN '' ELSE ', ' END + x.docs
			FROM	(
					SELECT	DISTINCT t.psvdoctype + '-' + t.psvdocno AS docs
					FROM	#tblTemp t
					INNER JOIN stkadj_details d ON
							d.adjdet_previous_fycode	= t.psvFycode	AND
							d.adjdet_previous_doctype	= t.psvdoctype	AND
							d.adjdet_previous_docno		= t.psvdocno
					WHERE	t.psvdoctype <> 'PSV'
					) x
			IF @strBadDocs <> ''
			BEGIN
				SET @strBadDocs = LEFT(@strBadDocs, 400)
				RAISERROR('These PSV documents were already adjusted: %s. Posting again would adjust the stock twice. Delete the earlier adjustment vouchers, or call the procedure with @intRepost = 1 to post anyway. Nothing was posted.', 16, 1, @strBadDocs)
				RETURN
			END
		END

		----ONE DATE FOR ALL VOUCHERS: the latest count date (zeroing voucher and adjustment voucher of a location carry the same date)
		SELECT	@dtAdjDate = MAX(psvdocdate)
		FROM	#tblTemp
		WHERE	ISNULL(PSVQty,0) <> 0 OR ISNULL(SystemQty,0) <> 0

		----LINES OF THE ZEROING VOUCHER: system qty -> 0   (positive stock goes DOWN, negative stock goes UP)
		INSERT INTO @tblLines (kind, location_code, StockCode, BATCHCODE, Qty, Rate, prev_doctype, prev_docno, prev_docsrno)
		SELECT	1, psvLocation, StockCode, NULL, SUM(SystemQty) * -1, MAX(Rate), MAX(psvdoctype), MAX(psvdocno), MAX(psvdocsrno)
		FROM	#tblTemp
		WHERE	ISNULL(SystemQty,0) <> 0
		GROUP BY psvLocation, StockCode
		HAVING	SUM(SystemQty) <> 0

		----LINES OF THE ADJUSTMENT VOUCHER: counted qty goes UP   (a negative count would go DOWN)
		INSERT INTO @tblLines (kind, location_code, StockCode, BATCHCODE, Qty, Rate, prev_doctype, prev_docno, prev_docsrno)
		SELECT	2, psvLocation, StockCode, MAX(BATCHCODE), SUM(PSVQty), MAX(Rate), psvdoctype, psvdocno, psvdocsrno
		FROM	#tblTemp
		WHERE	ISNULL(PSVQty,0) <> 0
		GROUP BY psvLocation, StockCode, psvdoctype, psvdocno, psvdocsrno

		----DOCUMENT NUMBERS: exactly 2 per location (1 = zeroing first, 2 = adjustment next); only vouchers that have lines get a number
		;WITH d AS
		(
			SELECT DISTINCT location_code, kind FROM @tblLines
		),
		n AS
		(
			SELECT location_code, kind, ROW_NUMBER() OVER(ORDER BY location_code, kind) AS rn FROM d
		)
		UPDATE	l
		SET		ADJDocNo = dbo.[fn_GetNewDocNoWithIncrementValue](@strADJDocType, NULL, n.rn)
		FROM	@tblLines l
		INNER JOIN n ON n.location_code = l.location_code AND n.kind = l.kind

		SELECT	@intDocCount = COUNT(DISTINCT ADJDocNo) FROM @tblLines

		----LINE NUMBERS INSIDE EVERY VOUCHER
		UPDATE	l
		SET		DocSrNo = r.rn
		FROM	@tblLines l
		INNER JOIN
				(
				SELECT	LineId, ROW_NUMBER() OVER(PARTITION BY ADJDocNo ORDER BY StockCode, LineId) AS rn
				FROM	@tblLines
				) r ON r.LineId = l.LineId

		----DOCUMENTS IN POSTING ORDER (zeroing voucher must be approved before the adjustment voucher of the same location)
		INSERT INTO @tblDocs (ADJDocNo)
		SELECT	ADJDocNo
		FROM	@tblLines
		GROUP BY ADJDocNo, location_code, kind
		ORDER BY location_code, kind

		SET @blnOwnTran = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END

		BEGIN TRY
			IF @blnOwnTran = 1
				BEGIN TRAN

			---------ADJUSTMENT DETAILS INSERTION
			INSERT INTO stkadj_details
						(
						adjdet_fycode,
						adjdet_doctype,
						adjdet_docno,
						adjdet_docsrno,
						adjdet_docdate,
						adjdet_stock_doctype,
						adjdet_stock_docno,
						adjdet_batch_docno,
						adjdet_stock_desc,
						adjdet_location_docno,
						adjdet_qty,
						adjdet_unit_docno,
						adjdet_rate,
						adjdet_amount,
						adjdet_updown_sign,
						adjdet_previous_fycode,
						adjdet_previous_doctype,
						adjdet_previous_docno,
						adjdet_previous_docsrno
						)
			SELECT		@strFyCode,
						@strADJDocType,
						l.ADJDocNo,
						l.DocSrNo,
						@dtAdjDate,
						stkmst_doctype,
						l.StockCode,
						l.BATCHCODE,
						stkmst_desc,
						l.location_code,
						ABS( l.Qty),
						stkmst_unit_docno,
						l.Rate,
						l.Rate * ABS( l.Qty),
						SIGN( l.Qty),
						@strFyCode,
						l.prev_doctype,
						l.prev_docno,
						l.prev_docsrno
			FROM		@tblLines l
			LEFT JOIN	stock_master ON
				l.StockCode = stkmst_docno

			---------ADJUSTMENT HEADER INSERTION
			INSERT INTO stkadj_header
						(
						adj_fycode,
						adj_doctype,
						adj_docno,
						adj_docdate,
						adj_net_amount,
						adj_location_docno,
						adj_total_qty,
						adj_narration,
						adj_created_by,
						adj_created_ts,
						ADJ_DIVN_DOCNO,
						ADJ_DEPT_DOCNO
						)
			SELECT		@strFyCode,
						@strADJDocType,
						l.ADJDocNo,
						@dtAdjDate,
						SUM( adjdet_amount),
						MAX(adjdet_location_docno),
						SUM( adjdet_qty),
						CASE WHEN MAX(l.kind) = 1 THEN 'PHYSICAL STOCK - ZEROING OF SYSTEM STOCK' ELSE 'PHYSICAL STOCK - COUNTED QTY' END + ' ' + ISNULL(@strRemarks,''),
						@strLoginID,
						GETDATE(),
						MAX(DM_DIVN_DOCNO),
						MAX(DM_DEPT_DOCNO)
			FROM 	(
					SELECT	DISTINCT ADJDocNo, kind
					FROM	@tblLines
					)l
			INNER JOIN	stkadj_details ON
				adjdet_fycode	= @strFyCode		AND
				adjdet_doctype	= @strADJDocType	AND
				adjdet_docno	= l.ADJDocNo
			INNER JOIN
					(
					SELECT *
					FROM	DOCUMENT_MASTER
					WHERE	DM_DOCNO = @strADJDocType
					)xx ON 1=1
			GROUP BY l.ADJDocNo

			-----UPDATING LASTNO MASTER (exactly the number of documents that were numbered)
			UPDATE	lastno_master
			SET		lastno_lastno = LASTNO_LASTNO + @intDocCount
			WHERE	lastno_doctype = @strADJDocType

			IF @blnOwnTran = 1
				COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF @blnOwnTran = 1 AND @@TRANCOUNT > 0
				ROLLBACK TRAN;
			THROW;
		END CATCH

		----ADJ DOCUMENT APPROVAL, ONE BY ONE IN ORDER: zeroing voucher first, then the adjustment voucher of the location
	--	DECLARE @intSeq INT = 1
	--	WHILE @intSeq <= ISNULL(@intDocCount,0)
	--	BEGIN
	--		SELECT	@strCurDocNo = ADJDocNo FROM @tblDocs WHERE seq = @intSeq

	--		SET	@strXmlDocDetails = '<FACTS><PARAMETERS>' +
	--					'<COLUMN1>' + @strADJDocType + '</COLUMN1>'+
	--					'<COLUMN2>' + @strCurDocNo + '</COLUMN2>'+
	--				'</PARAMETERS></FACTS>'

	--		EXEC [usp_DocumentAutoApprove]
	--				@strFycode				= @strFycode,
	--				@strDocType				= @strADJDocType,
	--				@strXmlDocDetails		= @strXmlDocDetails,
	--				@strLoginID				= @strLoginID,
	--				@strMachineId			= @@servername,
	--				@intFromBR				= 0

	--		SET @intSeq = @intSeq + 1
	--	END

	--	----CHECK THAT THE STOCK WAS REALLY POSTED FOR EVERY VOUCHER
	--	SET @strBadDocs = ''
	--	SELECT	@strBadDocs = @strBadDocs + CASE WHEN @strBadDocs = '' THEN '' ELSE ', ' END + d.ADJDocNo
	--	FROM	@tblDocs d
	--	WHERE	NOT EXISTS
	--			(
	--			SELECT	1
	--			FROM	stock_transaction
	--			WHERE	sttrn_fycode	= @strFycode		AND
	--					sttrn_doctype	= @strADJDocType	AND
	--					sttrn_docno		= d.ADJDocNo
	--			)

	--	IF @strBadDocs <> ''
	--	BEGIN
	--		----DIAGNOSTICS (only when posting failed): where do the lines get lost, and what does the posting procedure say when called directly
	--		SELECT	'DIAG_stage_counts' AS chk, d.ADJDocNo,
	--				(SELECT COUNT(*) FROM stkadj_header h WHERE h.adj_doctype = @strADJDocType AND h.adj_docno = d.ADJDocNo)								AS header_rows,
	--				(SELECT COUNT(*) FROM stkadj_details x WHERE x.adjdet_doctype = @strADJDocType AND x.adjdet_docno = d.ADJDocNo)							AS line_rows,
	--				(SELECT COUNT(*) FROM stkadj_details x WHERE x.adjdet_fycode = @strFycode AND x.adjdet_doctype = @strADJDocType AND x.adjdet_docno = d.ADJDocNo AND x.adjdet_qty <> 0)	AS lines_this_fy_qty,
	--				(SELECT COUNT(*) FROM stkadj_details x INNER JOIN stock_master m ON m.stkmst_doctype = x.adjdet_stock_doctype AND m.stkmst_docno = x.adjdet_stock_docno
	--				  WHERE x.adjdet_doctype = @strADJDocType AND x.adjdet_docno = d.ADJDocNo AND x.adjdet_qty <> 0 AND m.stkmst_nonqty = 0)					AS postable_lines,
	--				(SELECT COUNT(*) FROM stock_transaction t WHERE t.sttrn_doctype = @strADJDocType AND t.sttrn_docno = d.ADJDocNo)							AS stock_rows
	--		FROM	@tblDocs d

	--		SELECT	'DIAG_document_master' AS chk, dm_docno, dm_update_stock, dm_stock_up_or_down, dm_source_doctype
	--		FROM	document_master WHERE dm_docno = @strADJDocType

	--		SET @strCurDocNo = (SELECT TOP 1 ADJDocNo FROM @tblDocs ORDER BY seq)
	--		SET	@strXmlDocDetails = '<FACTS><PARAMETERS><COLUMN1>' + @strADJDocType + '</COLUMN1><COLUMN2>' + @strCurDocNo + '</COLUMN2></PARAMETERS></FACTS>'
	--		DECLARE @strDiagKey NVARCHAR(50) = 'DIAG-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)
	--		BEGIN TRY
	--			EXEC dbo.usp_ADJ_APPR_StockUpDation @strFycode, @strADJDocType, @strXmlDocDetails, @strLoginID, @strDiagKey OUTPUT
	--			SELECT 'DIAG_direct_call' AS chk, 'finished without error' AS result,
	--				   (SELECT COUNT(*) FROM stock_transaction t WHERE t.sttrn_doctype = @strADJDocType AND t.sttrn_docno = @strCurDocNo) AS stock_rows
	--		END TRY
	--		BEGIN CATCH
	--			SELECT 'DIAG_direct_call' AS chk, ERROR_NUMBER() AS err_no, ERROR_PROCEDURE() AS in_procedure, ERROR_LINE() AS at_line, ERROR_MESSAGE() AS message
	--		END CATCH

	--		RAISERROR('Adjustment vouchers %s (type %s) were created but the stock was NOT posted (no stock_transaction rows). Approve them from the voucher screen to see the error, or delete them before running again.', 16, 1, @strBadDocs, @strADJDocType)
	--	END
	--END
	end
	-------PREVIEW MODE
	ELSE
	BEGIN
		SET @strSQLString = 'SELECT StockCode, batchcode,PSVDate, ISNULL(PSVQty,0.000) AS PSVQty, isnull(SystemQty,0.000) as SystemQty,stkmst_desc AS StockDesc,
					 stkmst_desc, stkmst_unit_docno , Rate AS RATE, Amount AS AMOUNT'
				+ CASE WHEN ISNULL(@str_fields_list,'') = '' THEN '' ELSE ',' + @str_fields_list END
				+ ' FROM  #tblTemp
 					LEFT OUTER JOIN stock_master ON StockCode = stkmst_docno '
				+ ISNULL(@str_join_condition,'') + ' '
				+ CASE WHEN ISNULL(@str_order_by,'') = '' THEN ' ORDER BY ' ELSE @str_order_by END
				+ 'StockCode, batchcode'
		EXECUTE (@strSQLString)
	END
DROP TABLE #tblTemp
GO
