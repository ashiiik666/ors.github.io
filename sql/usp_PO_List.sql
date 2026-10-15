USE [FACTSERPFIRETECH]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
-----------------------------------------------------------------------------------------------------------------------
Author                : 
Date                  : 
Purpose               : 
Revision History:
-----------------------------------------------------------------------------------------------------------------------
Sl.No.	Date		Modified By		Notes
-----------------------------------------------------------------------------------------------------------------------
1		19-04-2017	Saneesh			Changes and Alignment done as per Facts standard
2		15-10-2026					Added GRN status (Pending for GRN / Partially Received / GRN Completed)
-----------------------------------------------------------------------------------------------------------------------
    
	EXEC	usp_PO_List 
			@strFyCode			=	N'CFY',
			@strDocType			=	N'PO',
			@strLoginId			=	N'saneesh.a',
			@nMaxRows			=	100000,
			@strModuleName		=	N'usp_PO_List',
			@strLayoutKey		=	N'',
			@strReserved		=	N'All',
			@nReserved			=	0,
			@strFilterCondition	=	N'2 = 2 and 1=1',
			@strFmDate			=	N'1992-01-01',
			@strToDate			=	N'2017-04-20'
-----------------------------------------------------------------------------------------------------------------------
*/
ALTER PROCEDURE [dbo].[usp_PO_List]
(
	@strFyCode					NVARCHAR( 6),
	@strDocType					NVARCHAR( 6),
	@strLoginId					NVARCHAR( 20),
	@nMaxRows					INT,
	@strModuleName				NVARCHAR( 200),
	@strLayoutKey				NVARCHAR( 50),
	@strReserved				NVARCHAR( 100),
	@nReserved					NUMERIC( 12,3),
	@strFilterCondition			NVARCHAR( 500) = NULL,
	@strFmDate					NVARCHAR( 30)  = NULL,
	@strToDate					NVARCHAR( 30)  = NULL
)
AS
BEGIN
	DECLARE	@strSQLString			NVARCHAR( MAX),
			@strRowCount			NVARCHAR( 20),    
			@strSourceDocType		NVARCHAR(20),
			@strRefDescription		Nvarchar(50)
	SET		@strRowCount			= LTRIM( @nMaxRows)	
	SET		@strFilterCondition		= NULLIF( ISNULL( @strFilterCondition,''),'')
	SET		@strFilterCondition		= ISNULL( @strFilterCondition,' 1 = 1')
	SET		@strFilterCondition		= ' AND '+ @strFilterCondition
	SET		@strFilterCondition	=	REPLACE(@strFilterCondition, '[Month]', 'DATENAME(MONTH, pur_docdate)')
	SET		@strFilterCondition	=	REPLACE(@strFilterCondition, '[PARTY NAME]', 'ap.acmst_desc')
	SELECT	@strSourceDocType	=	ISNULL( NULLIF( dm_ud_label6, ''), dm_source_doctype),	--Showing Relevant Caption in Listing
			@strRefDescription	=	ISNULL( NULLIF( dm_ref1_number_caption,''), 'REF NO.')	--Showing Ref Field Caption from Document Master
	FROM	document_master    
	WHERE	dm_docno			=	@strDocType   

	-- CAST to MAX first so the whole concatenation chain is NVARCHAR(MAX) (no 4000 char truncation)
	SET		@strSQLString = CAST(N'' AS NVARCHAR(MAX)) + '
			SELECT	TOP('+@strRowCount+') 
					0 AS SELECTION,
					pur_fycode,
					pur_doctype,
					pur_docno,
					pur_docdate,
					pur_ac_docno,
					pur_subledger_docno,
					pur_location_docno,
					pur_divn_docno,
					pur_curr_docno,
					pur_curr_rate,
					pur_narration,
					pur_ref,
					pur_ref1,
					pur_ref2,
					pur_gross_amount,
					pur_discount_amount,
					pur_discount_percent,
					pur_vat_amount,
					pur_net_amount,
					pur_created_by,
					pur_created_ts,
					pur_previous_fycode,
					pur_previous_doctype,
					pur_previous_docno,
					pur_document_status_docno,
					pur_posted_by,
					pur_posted_ts,
					pur_vat_treatment,
					pur_vat_treatment_docno,
					pur_vat_trn,
					pur_vat_rate_type,
					acmst_desc,
					ISNULL(PO.po_qty,0)								AS po_ordered_qty,
					ISNULL(GRN.grn_qty,0)							AS grn_received_qty,
					CASE WHEN ISNULL(PO.po_qty,0) > ISNULL(GRN.grn_qty,0) THEN ISNULL(PO.po_qty,0) - ISNULL(GRN.grn_qty,0) ELSE 0 END	AS pending_qty,
					CASE	WHEN ISNULL(GRN.grn_qty,0) = 0			THEN ''Pending for GRN''
							WHEN GRN.grn_qty < ISNULL(PO.po_qty,0)	THEN ''Partially Received''
							ELSE ''GRN Completed''
					END												AS grn_status
			FROM	purchase_header	WITH(NOLOCK)	
			INNER JOIN document_master	ON
					dm_docno	=	pur_docType
			INNER JOIN currency_master	ON
					curr_docno	=	pur_curr_docno
			left JOIN vw_accountmaster_report AP ON 
					ap.acmst_docno				=	pur_ac_docno	AND
					ap.acmst_subledger_docno	=	ISNULL(pur_subledger_docno,pur_ac_docno) 
			left JOIN document_status_master ON
					doc_status_docno = pur_document_status_docno
			OUTER APPLY (	SELECT	SUM(d.purdet_qty) AS po_qty
							FROM	purchase_details d WITH(NOLOCK)
							WHERE	d.purdet_fycode		= pur_fycode
							AND		d.purdet_doctype	= pur_doctype
							AND		d.purdet_docno		= pur_docno ) PO
			OUTER APPLY (	SELECT	SUM(g.purdet_qty) AS grn_qty
							FROM	purchase_details g WITH(NOLOCK)
							INNER JOIN purchase_header gh WITH(NOLOCK) ON
									gh.pur_fycode	= g.purdet_fycode	AND
									gh.pur_doctype	= g.purdet_doctype	AND
									gh.pur_docno	= g.purdet_docno
							WHERE	gh.pur_doctype				= ''GRN''
							AND		gh.pur_revised_docno IS NULL
							AND		g.purdet_previous_fycode	= pur_fycode
							AND		g.purdet_previous_doctype	= pur_doctype
							AND		g.purdet_previous_docno		= pur_docno ) GRN
			WHERE   pur_revised_docno IS NULL						AND
					pur_fycode		=	'''	+	@strFyCode	+ '''	AND
					pur_doctype		=	''' +	@strDocType + '''	AND
					pur_docdate		>=	''' +	@strFmdate  + '''	AND
					pur_docdate		<	''' +	@strTodate  + ''''	+ 
					@strFilterCondition		+
			' ORDER BY pur_docdate DESC '
	SET		@strSQLString = REPLACE( @strSQLString, '##FACTSREF##', @strRefDescription)      
	SET		@strSQLString = REPLACE( @strSQLString, '##FACTSDOCNO##',@strSourceDocType + ' No')      
    
	EXEC	(@strSQLString)
	EXEC	[usp_GRID_LoadGridSettings] @strLoginId,@strDocType,@strLayoutKey,@strModuleName,''
END
GO
