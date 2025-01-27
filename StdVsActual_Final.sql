ALTER VIEW StdvsActual_Final AS

WITH AllStdLabor AS (
  SELECT Name, WorkOrder, s.[Order ID] AS OrderNo, s.PartNo AS [Part No]
  , cpl.Description, BasePartNum, CustomLevel, QuantityOrdered AS OrderQty
  , SubtotalProduct AS TotalAdjustedPrice, s.SalesGroup, ShipDate, Brand
  , brand AS BrandStep3, s.TopGrp
  , CASE WHEN s.PartNo LIKE '%Kiosk%' AND s.PartNo NOT LIKE '%LAB%'
    THEN 'Kiosk' ELSE Brand END AS BrandStep4
  , CASE
    WHEN S.status IN ('Ship in Place', 'Shipped') THEN 'Shipped'
    WHEN PackCompleteDate IS NOT NULL THEN 'Packed'
    WHEN FinishQCDate IS NOT NULL THEN 'Packaging'
    WHEN [Finish Date] IS NOT NULL THEN 'FinalQC'
    WHEN [clear coat date] IS NOT NULL THEN 'Finish'
    WHEN [QC Date] IS NOT NULL THEN 'Paint'
    WHEN [Fab Date] IS NOT NULL THEN 'FabQC'
    WHEN [Cut Complete Date] IS NOT NULL THEN 'Fab'
    WHEN [Detail Date] IS NOT NULL THEN 'Cut'
    WHEN [Detail Date] IS NULL THEN 'Detail'
    END AS CurrentStatus
  , CASE
    WHEN [Fab Date] IS NOT NULL THEN [Fab Date]
    WHEN [Fab Date] IS NOT NULL AND RequiredDate >= GETDATE() THEN RequiredDate
    WHEN [Fab Date] IS NOT NULL AND RequiredDate < GETDATE() THEN GETDATE()
    END AS FabbingDate
  , [Finish Date], [Detail Date], [Enter Detail Date]
  , CASE
    WHEN [Fab Date] IS NOT NULL AND [Fab date] <= RequiredDate THEN 'FabOnTime'
    WHEN [Fab Date] IS NOT NULL AND [Fab Date] > RequiredDate THEN 'FabLate'
    WHEN [Fab Date] IS null AND RequiredDate >= GETDATE() THEN 'OnTime'
    WHEN [Fab Date] IS null AND RequiredDate < GETDATE() THEN 'Late'
    ELSE 'Error' END AS FabOnTimeStatus
  , Fabdate.Date AS FabCompleteDate
  , Fabdate.Year AS FabCompleteYear
  , Fabdate.QuarterNumber AS FabCompleteQTR
  , Fabdate.MonthNumber AS FabCompleteMonth
  , Fabdate.WeekNumber AS FabCompleteWK
  , Fabdate.Week_Friday AS FabCompleteWeek
  , Paintdate.Date AS PaintDate
  , Paintdate.Year AS ScheduledPaintYear
  , Paintdate.QuarterNumber AS ScheduledPaintQTR
  , Paintdate.MonthNumber AS ScheduledPaintMonth
  , Paintdate.WeekNumber AS ScheduledPaintWK
  , Paintdate.Week_Friday AS PaintCompleteWeek
  , Glassdate.Date AS GlassCompleteDate
  , Glassdate.Year AS ScheduledGlassYear
  , Glassdate.QuarterNumber AS ScheduledGlassQTR
  , Glassdate.MonthNumber AS ScheduledGlassMonth
  , Glassdate.WeekNumber AS ScheduledGlassWK
  , Glassdate.Week_Friday AS GlassCompleteWeek
  , Finishdate.Date AS FinishDate
  , Finishdate.Year AS FinishCompleteYear
  , Finishdate.QuarterNumber AS FinishCompleteQTR
  , Finishdate.MonthNumber AS FinishCompleteMonth
  , Finishdate.WeekNumber AS FinishCompleteWK
  , Finishdate.Week_Friday AS FinishCompleteWeek
  , Packdate.Date AS PackCompleteDate
  , Packdate.Year AS ScheduledPackYear
  , Packdate.QuarterNumber AS ScheduledPackQTR
  , Packdate.MonthNumber AS ScheduledPackMonth
  , Packdate.WeekNumber AS ScheduledPackWK
  , Packdate.Week_Friday AS PackCompleteWeek
  , Detaildate.Date AS DetailDate
  , Detaildate.Year AS DetailCompleteYear
  , Detaildate.QuarterNumber AS DetailCompleteQTR
  , Detaildate.MonthNumber AS DetailCompleteMonth
  , Detaildate.WeekNumber AS DetailCompleteWK
  , Detaildate.Week_Friday AS DetailCompleteWeek
  , Machinedate.Date AS MachineCompleteDate
  , Machinedate.Year AS ScheduledMachineYear
  , Machinedate.QuarterNumber AS ScheduledMachineQTR
  , Machinedate.MonthNumber AS ScheduledMachineMonth
  , Machinedate.WeekNumber AS ScheduledMachineWK
  , Machinedate.Week_Friday AS MachineCompleteWeek
  , BlownGlassdate.Date AS BlownGlassCompleteDate
  , BlownGlassdate.Year AS ScheduledBlownGlassYear
  , BlownGlassdate.QuarterNumber AS ScheduledBlownGlassQTR
  , BlownGlassdate.MonthNumber AS ScheduledBlownGlassMonth
  , BlownGlassdate.WeekNumber AS ScheduledBlownGlassWK
  , BlownGlassdate.Week_Friday AS BlownGlassCompleteWeek
  , shipdate.year AS SchedShipYear
  , shipdate.QuarterNumber AS SchedShipQTR
  , shipdate.WeekNumber AS SchedShipWeek
  , shipdate.MonthNumber AS SchedShipMonth
  , shipdate.Week_Friday AS ShipWeek
  , FinishQCDate, RequiredDate AS ScheduledFabDate, MMachineSetupOneHrs
  , MMachineSetupEachHrs, MMachineRunHrs
  , CNCMillSetupOneHrs, CNCMillSetupEachHrs, CNCMillRunTimeHrs
  , ISNULL(ActualDetHrs,0) AS WOActualDetHrs

  FROM SalesDollarsFinal_Products s
  INNER JOIN [Complete parts list] cpl ON cpl.[Part #] = s.PartNo
  INNER JOIN tblPaintDataEntry tpde ON s.Item = tpde.Item
  INNER JOIN [W-Order] w ON w.[W-Order] = tpde.WorkOrder

  --- Join date fields with dim_dates table
  LEFT OUTER JOIN DIM_Dates detaildate
    ON detaildate.Date = CAST(tpde.[Detail Date] AS DATE)
  LEFT OUTER JOIN DIM_Dates machinedate
    ON machinedate.Date = tpde.MachineCompleteDate -- Already a DATE
  LEFT OUTER JOIN DIM_Dates fabdate
    ON fabdate.Date = CAST(tpde.[Fab Date] AS DATE)
  LEFT OUTER JOIN DIM_Dates paintdate
    ON paintdate.Date = CAST(tpde.[Clear Coat Date] AS DATE)
  LEFT OUTER JOIN DIM_Dates Glassdate
    ON Glassdate.Date = CAST(tpde.[Glass Date] AS DATE)
  LEFT OUTER JOIN DIM_Dates finishdate
    ON finishdate.Date = CAST(tpde.[Finish Date] AS DATE)
  LEFT OUTER JOIN DIM_Dates Packdate
    ON Packdate.Date = tpde.[PackCompleteDate] -- Already a DATE
  LEFT OUTER JOIN DIM_Dates shipdate
    ON shipdate.Date = CAST(s.ShipDate AS DATE)
  LEFT OUTER JOIN DIM_Dates blownglassdate
    ON blownglassdate.Date = tpde.BlownGlassCompleteDate -- Already a DATE
)
, AddActLabor AS(
  SELECT asl.*
  , (ISNULL(EngActualHrs,0) + 0) AS ActualDetHrs
  , StdDetHrs
  , ISNULL(VarDetHrs,0) + ISNULL(VarRwkDetHrs,0) AS TotalDetVarHrs
  , StdFab
  , (ISNULL(FabActualHrs,0) + 0) AS TotalFabActual
  , ISNULL(VarFabHrs,0) + ISNULL(VarRwkFabHrs,0) AS TotalFabVarHrs
  , StdPaint
  , (ISNULL(PaintActualHrs,0) + 0) AS TotalPaintActualHrs
  , ISNULL(VarPaintHrs,0) + ISNULL(VarRwkPaintHrs,0) AS TotalPaintVarHrs
  , StdGlass
  , (ISNULL(GlassActualHrs,0) + 0) AS TotalGlassActualHrs
  , ISNULL(VarGlassHrs,0) + ISNULL(VarRwkGlassHrs,0) AS TotalGlassVarHrs
  , StdColdGlass
  , StdHotGlass
  , StdBlownGlass
  , (ISNULL(BlownGlassActualHrs,0) + 0) AS TotalBlownGlassActual
  , ISNULL(VarBlownGlassHrs,0) + ISNULL(VarRwkBlownGlassHrs,0) AS TotalBlownGlassVarHrs
  , StdFinish
  , (ISNULL(FinishActualHrs,0) + 0) AS TotalFinishActualHrs
  , ISNULL(VarFinishHrs,0) + ISNULL(VarRwkFinishHrs,0) AS TotalFinishVarHrs
  , StdHWPack
  , (ISNULL(HWPackActualHrs,0) + 0) AS TotalHWPackActualHrs
  , 0 AS TotalHWPackVarHrs
  , StdPack
  , (ISNULL(PackActualHrs,0) + 0) AS TotalPackActualHrs
  , ISNULL(VarPackHrs,0) + ISNULL(VarRwkPackHrs,0) AS TotalPackVarHrs
  FROM AllStdLabor asl
  LEFT OUTER JOIN StdHrs std 
    ON std.OrderID=asl.OrderNo AND std.WorkOrder=asl.WorkOrder
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS EngActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'Engineering'
    GROUP BY WO, Department
  ) AS eng ON asl.WorkOrder = eng.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarDetHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Engineering' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_Det ON asl.WorkOrder = Var_Det.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkDetHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Engineering' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_Det ON asl.WorkOrder = Var_Rework_Det.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS FabActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'Fabrication'
    GROUP BY WO, Department
  ) AS fab ON asl.WorkOrder = fab.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarFabHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Fabrication' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_fab ON asl.WorkOrder = Var_fab.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkFabHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Fabrication' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_fab ON asl.WorkOrder = Var_Rework_fab.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS FinishActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'Finish'
    GROUP BY WO, Department
  ) AS Finish ON asl.WorkOrder = Finish.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarFinishHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Finish' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_Finish ON asl.WorkOrder = Var_Finish.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkFinishHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Finish' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_finish ON asl.WorkOrder = Var_Rework_finish.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS PaintActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'Paint'
    GROUP BY WO, Department
  ) AS Paint ON asl.WorkOrder = Paint.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarPaintHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Paint' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_Paint ON asl.WorkOrder = Var_Paint.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkPaintHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Paint' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_Paint ON asl.WorkOrder = Var_Rework_Paint.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS GlassActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'Glass'
    GROUP BY WO, Department
  ) AS Glass ON asl.WorkOrder = Glass.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarGlassHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Glass' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_Glass ON asl.WorkOrder = Var_Glass.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkGlassHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Glass' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_Glass ON asl.WorkOrder = Var_Rework_Glass.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS HWPackActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'HWPack'
    GROUP BY WO, Department
  ) AS HWPack ON asl.WorkOrder = HWPack.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS PackActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'Packaging'
    GROUP BY WO, Department
  ) AS Pack ON asl.WorkOrder = Pack.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarPackHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Packaging' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_Pack ON asl.WorkOrder = Var_Pack.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkPackHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'Packaging' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_Pack ON asl.WorkOrder = Var_Rework_Pack.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(hrsused) AS BlownGlassActualHrs
    FROM Mfg_WO_RecordedLabor
    WHERE Department = 'BlownGlass'
    GROUP BY WO, Department
  ) AS BlownGlass ON asl.WorkOrder = BlownGlass.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarBlownGlassHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'BlownGlass' AND Rework = 0
    GROUP BY WO, Department
  ) AS Var_BlownGlass ON asl.WorkOrder = Var_BlownGlass.WO
  LEFT OUTER JOIN (
    SELECT WO, Department, SUM(variancehrs) AS VarRwkBlownGlassHrs
    FROM Mfg_WO_Variance
    WHERE Department = 'BlownGlass' AND Rework = 1
    GROUP BY WO, Department
  ) AS Var_Rework_BlownGlass ON asl.WorkOrder = Var_Rework_BlownGlass.WO
)
, Add_CH_MX AS (
  SELECT OrderNo AS OrNo, WorkOrder AS WO, SvA.[Part No] AS PartNo
  , COUNT(*) CNT, MexicoWO, SOD.ChinaWO
  , CASE WHEN MexicoWO=1 THEN 'MX'
    WHEN SOD.ChinaWO=1 THEN 'CN'
    ELSE 'SL' END AS WO_LOC
  FROM AddActLabor SvA
  LEFT JOIN [W-Order] ON [WorkOrder] = [W-Order]
  LEFT JOIN [S-Order Details] SOD ON [W-Order].[SO-Item]=SOD.Item
  GROUP BY OrderNo, WorkOrder, SvA.[Part No], MexicoWO, SOD.ChinaWO
  , CASE WHEN MexicoWO=1 THEN 'MX'
    WHEN SOD.ChinaWO=1 THEN 'CN'
    ELSE 'SL' END
)
, FINAL AS (
  SELECT AAL.*, WO_LOC
  FROM AddActLabor AAL
  LEFT JOIN Add_CH_MX ON WorkOrder=WO
)
SELECT * FROM FINAL
