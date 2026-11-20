# Power BI Dashboard – Build Guide (≈30–45 min)

Power BI files (.pbix) can only be made in Power BI Desktop, so this guide gives you the exact steps. Everything you need to load is already prepared.

## 1. Load the data
**Home → Get Data → Text/CSV**, load these three files: `sales.csv`, `products.csv`, `stores.csv`.
In **Transform Data (Power Query)**:
- `sales[order_date]` → type **Date**
- `sales[quantity]` → Whole Number; `unit_price`, `discount` → Decimal Number
- Remove nothing else – the data is already clean (see `Cleaning_Log` in the Excel file).

## 2. Date table
Modeling → New Table:
```
Date = ADDCOLUMNS(CALENDAR(DATE(2025,1,1), DATE(2025,12,31)),
        "Month", FORMAT([Date],"MMM"), "MonthNo", MONTH([Date]), "Quarter", "Q" & QUARTER([Date]))
```
Select the `Month` column → Column tools → **Sort by column → MonthNo**.

## 3. Data model (Model view)
| From (many) | To (one) |
|---|---|
| sales[product_id] | products[product_id] |
| sales[store_id] | stores[store_id] |
| sales[order_date] | Date[Date] |

All relationships: many-to-one, single direction. (Star schema: `sales` is the fact table.)

## 4. DAX measures (create in a "Measures" table)
```
Revenue        = SUMX(sales, sales[quantity] * sales[unit_price] * (1 - sales[discount]))
Total Orders   = DISTINCTCOUNT(sales[order_id])
Units Sold     = SUM(sales[quantity])
Avg Order Value = DIVIDE([Revenue], [Total Orders])
Discount Given = SUMX(sales, sales[quantity] * sales[unit_price] * sales[discount])
Revenue LM     = CALCULATE([Revenue], DATEADD('Date'[Date], -1, MONTH))
MoM Growth %   = DIVIDE([Revenue] - [Revenue LM], [Revenue LM])
Revenue Share % = DIVIDE([Revenue], CALCULATE([Revenue], ALL(products)))
```
Format: Revenue / AOV / Discount Given as currency (₹), growth and share as %.

## 5. Report layout (one page, 16:9)
| Position | Visual | Fields |
|---|---|---|
| Top row | 4 **Card** visuals | Revenue, Total Orders, Units Sold, Avg Order Value |
| Left, middle | **Line chart** | Axis: Date[Month]; Values: Revenue (monthly trend) |
| Right, middle | **Clustered bar** | Axis: products[category]; Values: Revenue |
| Bottom left | **Bar chart (Top N)** | Axis: products[product_name]; Values: Revenue; Filter → Top N = 10 by Revenue |
| Bottom middle | **Map** or bar | stores[region] / stores[city]; Values: Revenue |
| Bottom right | **Table** | category, Revenue, Revenue Share %, Discount Given |
| Left edge | **Slicers** | Date[Quarter], stores[region], products[category] |

## 6. Polish
- Title: "Retail Sales Dashboard – 2025". One colour theme (e.g., navy + one accent).
- Add data labels; turn off gridlines you don't need; sort bars descending.
- Test interactivity: click a region – every visual should re-filter.
- Take a screenshot of the finished page for your portfolio / GitHub README.
