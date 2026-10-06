import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

DATA = Path("../data")
OUT = Path("../python/output")
OUT.mkdir(exist_ok=True)

orders = pd.read_csv(DATA/"orders.csv", parse_dates=["Order_Date"])
ship = pd.read_csv(DATA/"shipments.csv", parse_dates=["Order_Date","Ship_Date","Delivery_Date","Promised_Delivery_Date"])
products = pd.read_csv(DATA/"products.csv")
warehouses = pd.read_csv(DATA/"warehouses.csv")
inventory = pd.read_csv(DATA/"inventory_snapshot.csv", parse_dates=["Snapshot_Month"])

print("Shapes:", orders.shape, ship.shape, products.shape, warehouses.shape, inventory.shape)
print("\nMissing values:")
print(orders.isna().sum())
print(ship.isna().sum())

# 1. Monthly orders and revenue
monthly = (orders.assign(Month=orders["Order_Date"].dt.to_period("M").astype(str))
           .groupby("Month")
           .agg(Orders=("Order_ID","count"), Units=("Quantity","sum"), Revenue=("Order_Value","sum"))
           .reset_index())

print("\nMonthly performance:")
print(monthly)

plt.figure(figsize=(10,5))
plt.plot(monthly["Month"], monthly["Orders"], marker="o")
plt.xticks(rotation=45)
plt.title("Monthly Order Volume")
plt.xlabel("Month")
plt.ylabel("Orders")
plt.tight_layout()
plt.savefig(OUT/"monthly_orders.png", dpi=150)
plt.close()

# 2. Delivery performance
valid = ship[ship["Status"].isin(["On Time","Delayed"])].copy()
on_time_pct = 100 * (valid["Status"].eq("On Time").mean())
avg_delivery = valid["Delivery_Days"].mean()
print(f"\nOn-time delivery: {on_time_pct:.2f}%")
print(f"Average delivery days: {avg_delivery:.2f}")

warehouse_perf = (ship[ship["Status"].isin(["On Time","Delayed"])]
                  .groupby("Warehouse_ID")
                  .agg(Shipments=("Order_ID","count"),
                       Avg_Delivery_Days=("Delivery_Days","mean"),
                       On_Time_Pct=("Status", lambda x: 100*(x=="On Time").mean()),
                       Avg_Delay_Days=("Delay_Days","mean"))
                  .reset_index()
                  .sort_values("On_Time_Pct"))

print("\nWarehouse performance:")
print(warehouse_perf)

plt.figure(figsize=(9,5))
plt.bar(warehouse_perf["Warehouse_ID"], warehouse_perf["On_Time_Pct"])
plt.axhline(on_time_pct, linestyle="--", label="Network average")
plt.title("On-Time Delivery by Warehouse")
plt.ylabel("On-Time %")
plt.legend()
plt.tight_layout()
plt.savefig(OUT/"warehouse_on_time.png", dpi=150)
plt.close()

# 3. Category analysis
cat = (orders.merge(products[["Product_ID","Category"]], on="Product_ID")
       .groupby("Category")
       .agg(Orders=("Order_ID","count"), Units=("Quantity","sum"), Revenue=("Order_Value","sum"))
       .reset_index()
       .sort_values("Revenue", ascending=False))

print("\nCategory performance:")
print(cat)

plt.figure(figsize=(9,5))
plt.bar(cat["Category"], cat["Revenue"])
plt.xticks(rotation=30)
plt.title("Revenue by Category")
plt.ylabel("Revenue")
plt.tight_layout()
plt.savefig(OUT/"category_revenue.png", dpi=150)
plt.close()

# 4. Inventory risk
inventory["Risk_Flag"] = np.where(
    (inventory["Stock_Level"] <= inventory["Reorder_Level"]) |
    (inventory["Days_of_Cover"] < 5),
    "At Risk", "Healthy"
)
risk_rate = 100 * inventory["Risk_Flag"].eq("At Risk").mean()
print(f"\nInventory records at risk: {risk_rate:.2f}%")

risk_by_wh = (inventory.groupby("Warehouse_ID")
              .agg(Risk_Rate=("Risk_Flag", lambda x: 100*(x=="At Risk").mean()),
                   Avg_Days_Cover=("Days_of_Cover","mean"))
              .reset_index()
              .sort_values("Risk_Rate", ascending=False))
print(risk_by_wh)

# 5. Insight extraction
print("\n--- Interview-ready observations ---")
print("Highest-delay warehouse:", warehouse_perf.iloc[0]["Warehouse_ID"])
print("Lowest-delay warehouse:", warehouse_perf.iloc[-1]["Warehouse_ID"])
print("Highest-revenue category:", cat.iloc[0]["Category"])
print("Highest inventory-risk warehouse:", risk_by_wh.iloc[0]["Warehouse_ID"])

# Save analytical tables
monthly.to_csv(OUT/"monthly_performance.csv", index=False)
warehouse_perf.to_csv(OUT/"warehouse_performance.csv", index=False)
cat.to_csv(OUT/"category_performance.csv", index=False)
risk_by_wh.to_csv(OUT/"inventory_risk_by_warehouse.csv", index=False)