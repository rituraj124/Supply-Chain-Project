CREATE DATABASE IF NOT EXISTS supply_chain_analytics;
USE supply_chain_analytics;

DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS inventory_snapshot;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS warehouses;

CREATE TABLE products (
    Product_ID VARCHAR(10) PRIMARY KEY,
    Product_Name VARCHAR(100),
    Category VARCHAR(50),
    Unit_Price DECIMAL(10,2),
    Supplier_ID VARCHAR(10)
);

CREATE TABLE suppliers (
    Supplier_ID VARCHAR(10) PRIMARY KEY,
    Supplier_Name VARCHAR(100),
    Supplier_Region VARCHAR(50),
    Lead_Time_Days INT
);

CREATE TABLE warehouses (
    Warehouse_ID VARCHAR(10) PRIMARY KEY,
    Warehouse_Name VARCHAR(100),
    Region VARCHAR(50),
    Capacity_Units INT
);

CREATE TABLE orders (
    Order_ID VARCHAR(15) PRIMARY KEY,
    Order_Date DATE,
    Customer_ID VARCHAR(15),
    Product_ID VARCHAR(10),
    Warehouse_ID VARCHAR(10),
    Quantity INT,
    Unit_Price DECIMAL(10,2),
    Order_Value DECIMAL(12,2)
);

CREATE TABLE shipments (
    Order_ID VARCHAR(15) PRIMARY KEY,
    Order_Date DATE,
    Warehouse_ID VARCHAR(10),
    Quantity INT,
    Ship_Date DATE,
    Delivery_Date DATE,
    Promised_Delivery_Date DATE,
    Delivery_Days INT,
    Status VARCHAR(20),
    Delay_Days INT,
    Product_ID VARCHAR(10)
);

CREATE TABLE inventory_snapshot (
    Snapshot_Month DATE,
    Warehouse_ID VARCHAR(10),
    Product_ID VARCHAR(10),
    Stock_Level INT,
    Reorder_Level INT,
    Days_of_Cover DECIMAL(10,2)
);