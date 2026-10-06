USE supply_chain_analytics;

-- 1. Monthly order volume and revenue
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
       COUNT(*) AS Orders,
       SUM(Quantity) AS Units,
       ROUND(SUM(Order_Value), 2) AS Revenue
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Month;

-- 2. On-time delivery rate
SELECT
    ROUND(100.0 * SUM(CASE WHEN Status = 'On Time' THEN 1 ELSE 0 END)
          / NULLIF(SUM(CASE WHEN Status IN ('On Time','Delayed') THEN 1 ELSE 0 END),0), 2) AS On_Time_Delivery_Pct
FROM shipments;

-- 3. Warehouse performance
SELECT w.Warehouse_ID, w.Warehouse_Name, w.Region,
       COUNT(s.Order_ID) AS Shipment_Count,
       ROUND(AVG(CASE WHEN s.Status <> 'Cancelled' THEN s.Delivery_Days END), 2) AS Avg_Delivery_Days,
       ROUND(100.0 * SUM(CASE WHEN s.Status='On Time' THEN 1 ELSE 0 END)
             / NULLIF(SUM(CASE WHEN s.Status IN ('On Time','Delayed') THEN 1 ELSE 0 END),0), 2) AS On_Time_Pct,
       ROUND(100.0 * SUM(CASE WHEN s.Status='Delayed' THEN 1 ELSE 0 END)
             / NULLIF(SUM(CASE WHEN s.Status IN ('On Time','Delayed') THEN 1 ELSE 0 END),0), 2) AS Delay_Pct
FROM warehouses w
LEFT JOIN shipments s ON w.Warehouse_ID=s.Warehouse_ID
GROUP BY w.Warehouse_ID, w.Warehouse_Name, w.Region
ORDER BY Delay_Pct DESC;

-- 4. Product/category contribution
SELECT p.Category,
       COUNT(DISTINCT o.Order_ID) AS Orders,
       SUM(o.Quantity) AS Units,
       ROUND(SUM(o.Order_Value),2) AS Revenue
FROM products p
JOIN orders o ON p.Product_ID=o.Product_ID
GROUP BY p.Category
ORDER BY Revenue DESC;

-- 5. Delayed orders by warehouse and month
SELECT Warehouse_ID,
       DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
       COUNT(*) AS Delayed_Orders,
       ROUND(AVG(Delay_Days),2) AS Avg_Delay_Days
FROM shipments
WHERE Status='Delayed'
GROUP BY Warehouse_ID, DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Delayed_Orders DESC;

-- 6. Stockout risk
SELECT i.Snapshot_Month, i.Warehouse_ID, i.Product_ID,
       i.Stock_Level, i.Reorder_Level, i.Days_of_Cover
FROM inventory_snapshot i
WHERE i.Stock_Level <= i.Reorder_Level OR i.Days_of_Cover < 5
ORDER BY i.Snapshot_Month, i.Days_of_Cover;

-- 7. Supplier lead-time exposure
SELECT s.Supplier_ID, s.Supplier_Name, s.Lead_Time_Days,
       COUNT(p.Product_ID) AS Product_Count,
       ROUND(AVG(p.Unit_Price),2) AS Avg_Product_Price
FROM suppliers s
LEFT JOIN products p ON s.Supplier_ID=p.Supplier_ID
GROUP BY s.Supplier_ID, s.Supplier_Name, s.Lead_Time_Days
ORDER BY s.Lead_Time_Days DESC;

-- 8. Top products by revenue
SELECT p.Product_ID, p.Product_Name, p.Category,
       SUM(o.Quantity) AS Units,
       ROUND(SUM(o.Order_Value),2) AS Revenue
FROM products p
JOIN orders o ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY Revenue DESC
LIMIT 10;

-- 9. Fulfillment funnel
SELECT
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN Status <> 'Cancelled' THEN 1 ELSE 0 END) AS Fulfilled_or_Shipped,
    SUM(CASE WHEN Status='On Time' THEN 1 ELSE 0 END) AS On_Time,
    SUM(CASE WHEN Status='Delayed' THEN 1 ELSE 0 END) AS `Delayed`,
    SUM(CASE WHEN Status='Cancelled' THEN 1 ELSE 0 END) AS Cancelled
FROM shipments;

-- 10. Warehouse capacity proxy using monthly average inventory
SELECT w.Warehouse_ID, w.Warehouse_Name,
       ROUND(AVG(i.Stock_Level),2) AS Avg_Stock_Level,
       w.Capacity_Units,
       ROUND(100.0*AVG(i.Stock_Level)/w.Capacity_Units,2) AS Avg_Capacity_Utilization_Pct
FROM warehouses w
JOIN inventory_snapshot i ON w.Warehouse_ID=i.Warehouse_ID
GROUP BY w.Warehouse_ID, w.Warehouse_Name, w.Capacity_Units
ORDER BY Avg_Capacity_Utilization_Pct DESC;