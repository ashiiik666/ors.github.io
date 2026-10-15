-- usp_SAL_DUMP_PreviousDocument : changes for the SEA60 / SE* previous-document branch
-- Location: ELSE IF @strPrevDocType IN ('SE10',...,'SEA60',...)  ->  final SELECT (FROM #Tmp_Table INNER JOIN sales_header ...)
--
-- Mapping requested (previous document -> this document):
--   SAL_BILL_TEL1  -> SAL_BILL_TEL1   (already fetched: "sal_bill_tel1,"  - no change)
--   SAL_BILL_TEL1  -> SAL_BILL_MOBILE (CHANGE 1)
--   SAL_BILL_FAX   -> SAL_VAT_TRN     (CHANGE 2)
--   SAL_BILL_EMAIL -> SAL_BILL_EMAIL  (already fetched: "sal_bill_email," - no change)

-- CHANGE 1 : in the column list, REPLACE
--					sal_ship_mobile,
--					sal_bill_mobile,
-- WITH
					sal_ship_mobile,
					sal_bill_tel1					AS SAL_BILL_MOBILE,

-- CHANGE 2 : near the end of the same column list, REPLACE
--					tmp_VAT						AS		SAL_VAT_TRN ,
-- WITH
					sal_bill_fax				AS		SAL_VAT_TRN ,
