ALTER VIEW CostMarginStudio AS

WITH cost AS (
  SELECT Product, sum(ExtCost) AS TotalCost
  , SUM(IIF(HotGlass=0, ExtCost, 0)) AS MfgCost
  , SUM(IIF(HotGlass=1, ExtCost, 0)) AS GlassCost
  , SUM(IIF(WarmGlass=1, ExtCost, 0)) AS WarmGlassCost
  , SUM(IIF(Labor=0, ExtCost, 0)) AS MatCost
  , SUM(IIF(Labor=1, ExtCost, 0)) AS LaborCost
  , SUM(IIF(Labor=0 AND HotGlass=0, ExtCost, 0)) AS MfgMatCost
  , SUM(IIF(Labor=1 AND HotGlass=0, ExtCost, 0)) AS MfgLaborCost
  , SUM(IIF(Labor=0 AND HotGlass=1, ExtCost, 0)) AS GlassMatCost
  , SUM(IIF(Labor=1 AND HotGlass=1, ExtCost, 0)) AS GlassLaborCost
  , SUM(IIF(Labor=0 AND WarmGlass=1, ExtCost, 0)) AS WarmGlassMatCost
  , SUM(IIF(Labor=1 AND WarmGlass=1, ExtCost, 0)) AS WarmGlassLaborCost
  , SUM(IIF(Acrylic=1, ExtCost, 0)) AS AcrylicMatCost
  , SUM(IIF(DeptEng=1, ExtCost, 0)) AS DeptEng
  , SUM(IIF(DeptFab=1, ExtCost, 0)) AS DeptFab
  , SUM(IIF(DeptFinish=1, ExtCost, 0)) AS DeptFinish
  , SUM(IIF(DeptGlassCold=1, ExtCost, 0)) AS DeptGlassCold
  , SUM(IIF(DeptGlassHot=1, ExtCost, 0)) AS DeptGlassHot
  , SUM(IIF(DeptGlassWarm=1, ExtCost, 0)) AS DeptGlassWarm
  , SUM(IIF(DeptMachine=1, ExtCost, 0)) AS DeptMachine
  , SUM(IIF(DeptPack=1, ExtCost, 0)) AS DeptPack
  , SUM(IIF(DeptPaint=1, ExtCost, 0)) AS DeptPaint
  , SUM(IIF(DeptOther=1, ExtCost, 0)) AS DeptOther
  FROM CostByBOM AS cb
  GROUP BY Product
), subassm AS (
  SELECT Parent, MIN(Parts) as SubAssembly
  FROM [BILL of MAT]
  WHERE Parent like '__B00%' and Parts like '__B____-%'
  GROUP BY Parent
), final AS (
  SELECT cb.*, LEFT(c.[part #],10) AS BasePart2, SubAssembly
  , price2 AS PriceRetail, price4 AS PriceDNet
  , IIF(price4!=0, round(1-(TotalCost/price4),4), NULL) AS MarginPct
  , IIF(cb.Product like 'CU-%' OR cb.Product like 'D%', 1, 0) AS Custom
  , IIF(cb.Product like 'SV-%', 1, 0) AS ServiceOrder
  , IIF(cb.Product like 'RPLC-%', 1, 0) AS Replacement
  , IIF(cb.Product like '%B00%', 1, 0) AS Studio, c.Inactive, c.QuickShip
  , IIF(c.[Part #] LIKE '__B00__-__-GM-%' OR
	 c.[Part #] LIKE '__B00__-__-HB-%' OR
	 c.[Part #] LIKE '__B00__-__-SN-%' OR 
	 c.[Part #] LIKE '__B00__-__-RB-%', 1, 0) AS translucent
  , IIF(c.[Part #] LIKE '__B00__-__-__-C-%' OR
 	c.[Part #] LIKE '__B00__-__-__-_C-%', 0, 1) AS colored_glass
  , c.Type, c.Dwg, c.Description, c.L1, c.W1, c.H1, c.Wg1
  , c.MexicoTransferDate, IIF(c.MexicoTransferDate<=GETDATE(),1,0) AS MexicoMfg
  , SUBSTRING(cb.Product, PATINDEX('%[0-9][0-9][0-9][0-9]%', cb.Product) ,4)
    AS CollectionNumber
  , p.ProductNumber AS BasePart, p.ProductName, p.Collection, p.Material, p.Platform
  , p.ProductFunction, p.W, p.D, p.Diameter, p.OAH
  FROM cost AS cb
  LEFT JOIN subassm AS s ON cb.Product=s.Parent
  LEFT JOIN [Complete parts list] AS c ON cb.Product=c.[Part #]
  LEFT JOIN Products AS p ON cb.Product LIKE CONCAT(p.ProductNumber,'%')
)
SELECT * FROM final 
