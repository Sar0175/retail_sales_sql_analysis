# Retail Sales Performance Analysis — SQL Project
### Interview Prep Document

---

## 1. Project Summary (Resume Bullet)

> **Retail Sales Performance Analysis (SQL, SQLite/MySQL)**
> Analyzed 9,800 retail transactions (2022–2024) across 4 US regions using SQL to uncover sales trends, profit drivers, and loss-making segments. Used window functions, CTEs, and aggregate queries to build a region/category profitability model; identified that the Furniture category consistently operates at <4% profit margin across all regions, and flagged a 6.2% YoY sales decline in 2024 for leadership review.

---

## 2. The Problem You "Solved"

A retail company (Superstore-style dataset: Orders, Customers, Products, Region, Category, Discount, Profit) wants to understand:
- Where is revenue coming from, and is it growing?
- Which categories/regions are actually profitable vs. just generating revenue?
- Are high discounts destroying margin?
- Who are the most valuable repeat customers?

This is a classic **business intelligence / sales analytics** use case — the kind of thing a Data Analyst does in their first month at almost any company.

---

## 3. Dataset

- **9,800 order-level transactions**, Jan 2022 – Dec 2024
- Columns: `order_id, order_date, ship_date, ship_mode, customer_id, segment, region, state, category, sub_category, quantity, unit_price, discount, sales, profit`
- 3 categories (Furniture, Office Supplies, Technology), 4 regions, 3 customer segments (Consumer, Corporate, Home Office)
- This mirrors the well-known public **"Sample Superstore"** dataset structure — if asked "where's the data from," you can honestly say you modeled it on the standard Superstore sales dataset commonly used for SQL/BI practice, with your own generated transaction-level records.

**Table schema:**
```sql
CREATE TABLE orders (
    order_id TEXT, order_date TEXT, ship_date TEXT, ship_mode TEXT,
    customer_id TEXT, segment TEXT, region TEXT, state TEXT,
    category TEXT, sub_category TEXT, quantity INTEGER,
    unit_price REAL, discount REAL, sales REAL, profit REAL
);
```

---

## 4. What You Did — Step by Step

1. **Loaded the data** into a SQL database (SQLite for practice; same queries work in MySQL/PostgreSQL/Power BI with minor date-function syntax changes).
2. **Wrote 10 analytical queries** covering trend analysis, profitability, loss detection, and customer segmentation.
3. **Used window functions** (`SUM() OVER`, `LAG()`, `RANK()`) to compute running totals, year-over-year growth, and rankings — without collapsing the underlying rows.
4. **Used CTEs (`WITH` clauses)** to break complex logic into readable steps instead of nested subqueries.
5. **Interpreted the output** into business insights (below) — this is the part interviewers care about most: not just "I can write SQL" but "I can turn SQL output into a decision."

---

## 5. The Queries + Actual Results (run this yourself before the interview)

### Query 1 — Overall snapshot
```sql
SELECT COUNT(*) AS total_orders, ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(SUM(profit)*100.0/SUM(sales),2) AS profit_margin_pct
FROM orders;
```
**Result:** 9,800 orders | $9.2M total sales | $1.11M total profit | **12.07% overall margin**

### Query 2 — Yearly trend
```sql
SELECT strftime('%Y', order_date) AS year, ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit
FROM orders GROUP BY year ORDER BY year;
```
| Year | Sales | Profit |
|---|---|---|
| 2022 | $3.05M | $356.6K |
| 2023 | $3.18M | $387.7K |
| 2024 | $2.98M | $366.3K |

**Insight:** Sales grew in 2023 then **dipped 6.2% in 2024** — a red flag worth investigating (seasonality? discounting? churn?).

### Query 3 — Top sub-categories by revenue
**Result:** Copiers ($3.8M), Machines ($2.15M), Phones ($1.31M) are the top 3 — all **Technology**. Note Copiers alone drives ~41% of total revenue.

### Query 4 — Region × Category margin (GROUP BY + HAVING)
```sql
SELECT region, category, ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(SUM(profit)*100.0/SUM(sales),2) AS margin_pct
FROM orders GROUP BY region, category HAVING margin_pct < 5 ORDER BY margin_pct ASC;
```
**Result:** Every single region's **Furniture** category has margin under 4% (West 2.22%, Central 2.35%, East 2.99%, South 3.71%) — this is the **single strongest insight** in the project.

### Query 5 — Loss-making orders
**Result:** Loss-making orders are concentrated in **Technology (Copiers, Machines) and Furniture**, all with **avg. discount ~40–45%**. Office Supplies rarely loses money even at 50% discount because unit prices/margins are structurally different.

**Insight:** High discounting is the direct cause of negative-profit orders — not the category itself.

### Query 6 — Running total (window function)
```sql
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS month, SUM(sales) AS monthly_sales
    FROM orders GROUP BY month
)
SELECT month, ROUND(monthly_sales,2) AS monthly_sales,
       ROUND(SUM(monthly_sales) OVER (ORDER BY month),2) AS running_total_sales
FROM monthly ORDER BY month;
```
Shows cumulative revenue growth month by month — used for a cumulative sales curve.

### Query 7 — YoY growth using LAG()
| Year | Sales | Prev Year | YoY % |
|---|---|---|---|
| 2022 | $3.05M | — | — |
| 2023 | $3.18M | $3.05M | **+4.23%** |
| 2024 | $2.98M | $3.18M | **−6.18%** |

### Query 8 — Top 3 profitable sub-categories per region (RANK)
Consistent across **all 4 regions**: Copiers → Machines → Phones are the top 3 profit drivers everywhere.

### Query 9 — Segment performance
Home Office, Consumer, and Corporate segments are nearly balanced (~$2.9–3.1M each) — no single segment dominates, meaning the customer base is diversified.

### Query 10 — Top repeat customers
Identified top 10 customers by spend among those with 5+ orders (e.g., CUST-0161 with 20 orders / $40.6K) — these are candidates for a loyalty/retention program.

---

## 6. The 3 Headline Insights (say these out loud in the interview)

1. **"Furniture is a margin trap."** It generates decent revenue but under 4% margin in every region — likely due to high shipping/handling costs relative to price, worsened by frequent discounting.
2. **"2024 sales dropped 6.2% year-over-year"** after growing 4.2% in 2023 — a trend that needs root-cause analysis (seasonality vs. real decline).
3. **"Discounting above ~40% flips orders to a loss"** — almost all loss-making orders cluster around 40–50% discount regardless of category, suggesting a discount policy cap could directly protect profit.

---

## 7. SQL Concepts You Can Speak To

| Concept | Where used | What to say if asked |
|---|---|---|
| `GROUP BY` / `HAVING` | Region-category margin | "HAVING filters on the aggregated result, unlike WHERE which filters rows before aggregation." |
| Window functions (`SUM() OVER`, `LAG()`, `RANK()`) | Running total, YoY growth, ranking | "Window functions let me compute per-row calculations across a partition without collapsing the result set — unlike GROUP BY, I keep every row visible." |
| CTEs (`WITH`) | Monthly/yearly rollups | "CTEs make multi-step logic readable and let me reference the same intermediate result multiple times without repeating the subquery." |
| Subqueries | Top repeat customers | "Used a subquery in the WHERE clause to first filter customers with 5+ orders, then aggregated their spend." |
| Date functions | `strftime()` for year/month extraction | "In MySQL I'd use YEAR()/DATE_FORMAT(); in SQLite it's strftime(); in Postgres, DATE_TRUNC()." |

---

## 8. Likely Interview Questions & Answers

**Q: Why window functions instead of GROUP BY for running totals?**
A: GROUP BY collapses rows into one per group, so you lose the individual month rows. `SUM() OVER (ORDER BY month)` keeps every row and adds a running total alongside it — needed for a cumulative trend line.

**Q: How would you optimize this if the table had 50 million rows?**
A: Add indexes on `order_date`, `region`, and `category` (the columns used in GROUP BY/WHERE), consider pre-aggregated summary tables for dashboards refreshed daily rather than querying raw transactions every time, and partition by year if the database supports it.

**Q: What would you do next with this analysis?**
A: Investigate the 2024 decline by month to see if it's concentrated in specific quarters; run a controlled test capping Furniture discounts to see if margin improves without hurting volume; build a Power BI/Tableau dashboard so stakeholders can self-serve instead of requesting ad hoc queries.

**Q: SQL vs Excel — why use SQL here?**
A: At 9,800+ rows across many dimensions, SQL scales better than Excel PivotTables, keeps the analysis reproducible/version-controlled, and window functions do in one query what would take several helper columns in Excel.

---

## 9. Files From This Project

- `retail_sales.csv` — the raw dataset (9,800 rows)
- `queries.sql` — all 10 queries, ready to run
- This document — your talking points

**Tonight, before the interview:** open the CSV in Excel/Google Sheets once, skim it for 2 minutes, and re-read Section 6 (headline insights) and Section 8 (Q&A) twice. That's enough to speak about this confidently.
