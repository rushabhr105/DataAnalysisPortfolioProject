ALTER VIEW StdHrs_AllDepartments AS


WITH optionsdetail AS 

(SELECT [Order ID], [End Item], CASE WHEN [Part No] = [End Item] THEN Item ELSE [End Item] END AS Item, CASE WHEN [part no] = [End Item] THEN Quantity ELSE 0 END AS Quantity, quantity*fab  AS fab, quantity*Paint AS Paint, quantity*Finish AS Finish, quantity*Pack AS Pack
		FROM [S-Order Details] sd
		LEFT OUTER JOIN options opt
		ON opt.[Option] = sd.[Part No]
		AND opt.Product = sd.[End Item]
		
		) 

, opts AS (
		SELECT  [Order ID], Item,  
			SUM(CASE WHEN fab IS NULL THEN 0 ELSE fab END) AS OptsFab, 
			SUM(CASE WHEN paint IS NULL THEN 0 ELSE paint END) AS OptsPaint,
			SUM(CASE WHEN finish IS NULL THEN 0 ELSE Finish END) AS OptsFinish,
			SUM(CASE WHEN pack IS NULL THEN 0 ELSE Pack END) AS OptsPack
	 
		FROM optionsdetail od
			GROUP BY [Order ID], [End Item],Item

	)

, stdoptionhrs AS (

SELECT sd.[Order ID],CAST(sp.orderdate AS DATE) AS OrderDate, WorkOrder ,sd.Quantity,--parent ,parts, bom.qty, type, parts2, qty2, type2, parts3, qty3, type3, parts4, qty4, type4,
	OptsFab, OptsFinish, OptsPack, OptsPaint,
	stdhrs.*,

	CASE  WHEN STD.PackCompleteDate IS NULL THEN sp.OrderShip 
		ELSE PackCompleteDate
		END AS PackCompleteDate, 
	CAST(DATEADD(day, -7,CASE WHEN  std.PackCompleteDate IS NULL THEN sp.OrderShip ELSE PackCompleteDate END) AS DATETIME) AS BlownGlassDate,
	CASE WHEN std.GlassCompleteDate IS NULL AND PackCompleteDate IS NULL THEN DATEADD(day, -7,sp.OrderShip)
		WHEN std.GlassCompleteDate IS NULL AND PackCompleteDate IS NOT NULL THEN DATEADD(day,-6,PackCompleteDate)
		ELSE std.glasscompletedate 
	END AS WarmGlassDate,
					
	CAST([Finish Date] AS DATETIME) AS FinishDate,
	CAST(std.[Clear Coat Date] AS DATETIME) AS PaintDate,
	CAST(std.[fab date] AS DATETIME) AS FabDate,
	sp.Brand,
	SubtotalProduct AS Revenue,
	CASE WHEN sp.Brand = 'Studio' THEN SubtotalProduct ELSE 0 END AS Studio_Revenue,
	CASE WHEN sp.Brand = 'Signature' THEN SubtotalProduct ELSE 0 END AS Signature_Revenue


FROM opts
	INNER JOIN [S-Order Details] sd
	ON sd.[Order ID] = opts.[Order ID] 
	AND sd.Item = opts.Item

	LEFT OUTER JOIN Products_StandardHours_All stdhrs ON sd.[Part No] = stdhrs.partno
	INNER JOIN [S-Order] so ON so.[Order ID] = sd.[Order ID]


	INNER JOIN SalesDollarsFinal_Products sp
		ON sp.PartNo = sd.[Part No]
		AND sd.[Order ID] = sp.[Order ID]
	INNER JOIN [W-Order] w ON w.[SO-Item] = sd.Item
	LEFT OUTER JOIN tblPaintDataEntry std ON w.[W-Order] = std.WorkOrder AND std.Item = sp.Item

	WHERE so.[cus order date]> '1/1/2019' 
AND so.Status <> 'Quote' AND so.Status <> 'Cancel'

)

, stdhrsaddbrand AS (
SELECT [Order ID] AS OrderID, Orderdate,  WorkOrder, Quantity AS OrderQty, PartNo, SUM(studio_FabstdHrs)*Quantity AS Studio_FabStdHrs, 
	SUM(Studio_FinishStdHrs)*Quantity AS Studio_FinishStdHrs, SUM(Signature_FabStdHrs)*quantity +MAX(OptsFab) AS Signature_FabStdHrs, SUM(Signature_FinishStdHrs)*Quantity+MAX(OptsFinish) AS Signature_FinishStdHrs, SUM(PaintHrs)*Quantity+MAX(OptsPaint) AS PaintStdHrs,
	SUM(PackHrs)*Quantity+MAX(OptsPack) AS PackStdHrs, SUM(WarmGlassHrs)*Quantity AS WarmGlassStdHrs, SUM(Hot_BlownGlassHrs)*Quantity+SUM(cold_BlownGlassHrs)*Quantity AS BlownGlassStdHrs,
	Revenue, 
	Signature_Revenue,
	Studio_Revenue, 
	CASE WHEN brand = 'Studio' OR brand = 'Retail Inventory' THEN 'Studio' ELSE Brand END AS Brand,

		CAST(CASE WHEN (((DATEPART(dw, PackCompleteDate)-1) + @@DATEFIRST)%7) = 6 THEN DATEADD(day, -1, PackCompleteDate) 
				WHEN (((DATEPART(dw, PackCompleteDate)-1) + @@DATEFIRST)%7) = 0 
				THEN DATEADD(day, 1, PackCompleteDate) ELSE PackCompleteDate END AS DATE) AS PackCompleteDate,
		CAST(CASE WHEN (((DATEPART(dw, BlownGlassDate)-1) + @@DATEFIRST)%7) = 6 THEN DATEADD(day, -1, BlownGlassDate) 
				WHEN (((DATEPART(dw, BlownGlassDate)-1) + @@DATEFIRST)%7) = 0 
				THEN DATEADD(day, 1, BlownGlassDate) ELSE BlownGlassDate END AS DATE) AS BlownGlassDate,
		CAST(CASE WHEN (((DATEPART(dw, WarmGlassDate)-1) + @@DATEFIRST)%7) = 6 THEN DATEADD(day, -1, WarmGlassDate) 
				WHEN (((DATEPART(dw, WarmGlassDate)-1) + @@DATEFIRST)%7) = 0 
				THEN DATEADD(day, 1, WarmGlassDate) ELSE WarmGlassDate END AS DATE) AS WarmGlassDate,
		CAST(CASE WHEN (((DATEPART(dw, FinishDate)-1) + @@DATEFIRST)%7) = 6 THEN DATEADD(day, -1, FinishDate) 
				WHEN (((DATEPART(dw, FinishDate)-1) + @@DATEFIRST)%7) = 0 
				THEN DATEADD(day, 1, FinishDate) ELSE FinishDate END AS DATE) AS FinishDate,	
		CAST(CASE WHEN (((DATEPART(dw, PaintDate)-1) + @@DATEFIRST)%7) = 6 THEN DATEADD(day, -1, PaintDate) 
				WHEN (((DATEPART(dw, PaintDate)-1) + @@DATEFIRST)%7) = 0 
				THEN DATEADD(day, 1, PaintDate) ELSE PaintDate END AS DATE) AS PaintDate,			
		CAST(CASE WHEN (((DATEPART(dw, FabDate)-1) + @@DATEFIRST)%7) = 6 THEN DATEADD(day, -1, FabDate) 
				WHEN (((DATEPART(dw, FabDate)-1) + @@DATEFIRST)%7) = 0 
				THEN DATEADD(day, 1, FabDate) ELSE FabDate END AS DATE) AS FabDate			


FROM stdoptionhrs
GROUP BY [Order ID], Orderdate, WorkOrder, Quantity, partno,Revenue, Signature_Revenue, Studio_Revenue, Brand, PackCompleteDate, BlownGlassDate, PaintDate, FabDate, FinishDate, WarmGlassDate


) 


SELECT stdhrsaddbrand.*, Signature_FabStdHrs+Studio_FabStdHrs+PaintStdHrs+Studio_FinishStdHrs+Signature_FinishStdHrs+BlownGlassStdHrs+WarmGlassStdHrs+PackStdHrs AS TotalStdHrs

FROM stdhrsaddbrand


