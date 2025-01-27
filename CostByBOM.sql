ALTER VIEW CostByBOM AS

WITH bom AS ( --Bom Ext totals by product and partnum
  SELECT Product, PartNum, SUM(ExtQty) AS ExtQty
  FROM DIM_BOM_cache
  GROUP BY Product, PartNum
), bom_parents AS ( -- BOM Parents
  SELECT DISTINCT parent, Parts
  FROM [BILL of MAT]
), bom_leaves AS ( -- BOM Leaves
  SELECT cp.[part #] AS partnum
  FROM [Complete parts list] AS cp
  LEFT JOIN bom_parents AS b ON cp.[part #] = b.parent
  WHERE b.parent IS NULL
), final AS (
  SELECT Product, bom.PartNum, c.[description]
  , ExtQty, UnitCost, ExtQty * UnitCost AS ExtCost
  , IIF(bom.PartNum LIKE 'Labor%', 1, 0) AS Labor
  , IIF(bom.PartNum IN (
        '32-002-07021','32-002-07001','32-002-05005','32-002-05006',
        'Labor-BlownGlass','Labor-BlownGlass-Cold','Labor-BlownGlass-Hot',
        'Labor-ColdGlass-MX','Labor-HotGlass-MX'), 1, 0) AS HotGlass
  , IIF(bom.PartNum IN ('Labor-WarmGlass','Labor-WarmGlass-MX') OR 
        bom.PartNum LIKE '23-001-%' OR 
        bom.PartNum LIKE '31-00[23]%', 1, 0) AS WarmGlass
  , IIF(bom.PartNum LIKE '23-002-%' OR 
        bom.PartNum LIKE '31-001-%', 1, 0) AS Acrylic
  , IIF(bom.PartNum IN ('Labor-Detail','Labor-Detail Quote',
        'Labor-DetailQC'), 1, 0) AS DeptEng
  , IIF(bom.PartNum IN ('Labor-Fabrication','Labor-Fabrication-MX'
        ), 1, 0) AS DeptFab
  , IIF(bom.PartNum IN ('Labor-Finish','Labor-Finish-MX'
        ), 1, 0) AS DeptFinish
  , IIF(bom.PartNum IN ('Labor-BlownGlass-Cold','Labor-ColdGlass-MX'
        ), 1, 0) AS DeptGlassCold
  , IIF(bom.PartNum IN ('Labor-BlownGlass','Labor-BlownGlass-Hot',
        'Labor-HotGlass-MX',''), 1, 0) AS DeptGlassHot
  , IIF(bom.PartNum IN ('Labor-WarmGlass','Labor-WarmGlass-MX'), 1, 0) AS DeptGlassWarm
  , IIF(bom.PartNum IN ('Labor-CNCMill-RunTime','Labor-CNCMill-SetupEach',
        'Labor-CNCMill-SetupOneTime','Labor-ManualMachine-Runtime',
        'Labor-ManualMachine-SetupEach','Labor-ManualMachine-SetupOneTime'
        ), 1, 0) AS DeptMachine
  , IIF(bom.PartNum IN ('Labor-Packaging','Labor-Pack-MX','',''
        ), 1, 0) AS DeptPack
  , IIF(bom.PartNum IN ('Labor-Paint','Labor-Paint-MX','',''
        ), 1, 0) AS DeptPaint
  , IIF(bom.PartNum IN ('Labor-Photo','Labor-QC','SV-Labor-Paint'
        ), 1, 0) AS DeptOther
  FROM bom
  INNER JOIN bom_leaves AS bl ON bom.PartNum = bl.partnum
  LEFT JOIN CostByPurchaseOrCPL AS pc ON bl.partnum = pc.partnum
  LEFT JOIN [Complete parts list] AS c on bom.partnum=c.[Part #]
)
SELECT * FROM final
