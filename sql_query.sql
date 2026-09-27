use retail_sales;
-- =====================================================================
-- RETAIL SALES PERFORMANCE ANALYSIS
-- Dataset: orders (9,800 transactions, 2022-2024, 4 US regions)
-- =====================================================================

-- 1. Overall business snapshot
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_margin_pct
FROM orders;

-- 2. Yearly sales & profit trend
SELECT
    YEAR(order_date) AS year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY year
ORDER BY year;

-- 3. Top 10 sub-categories by revenue
SELECT
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(*) AS orders
FROM orders

-- 4. Region-wise & category-wise profitability (GROUP BY + HAVING)
SELECT region, category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS margin_pct
FROM orders
GROUP BY region, category
HAVING margin_pct < 5
ORDER BY margin_pct ASC;

-- 5. Loss-making orders (negative profit)
SELECT
    category,
    sub_category,
    COUNT(*) AS loss_making_orders,
    ROUND(SUM(profit), 2) AS total_loss,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM orders
WHERE profit < 0
GROUP BY category, sub_category
ORDER BY total_loss ASC;

-- 6. Running total of monthly sales using a window function
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY month
)
SELECT
    month,
    ROUND(monthly_sales, 2) AS monthly_sales,
    ROUND(SUM(monthly_sales) OVER (ORDER BY month), 2) AS running_total_sales
FROM monthly
ORDER BY month;
GROUP BY sub_category
ORDER BY total_sales DESC
LIMIT 10;

-- 7. Year-over-year growth using LAG()
WITH yearly AS (
    SELECT YEAR(order_date) AS year, SUM(sales) AS total_sales
    FROM orders
    GROUP BY year
)
SELECT
    year,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(LAG(total_sales) OVER (ORDER BY year), 2) AS prev_year_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year)) * 100.0
        / LAG(total_sales) OVER (ORDER BY year), 2
    ) AS yoy_growth_pct
FROM yearly
ORDER BY year;

-- 8. Rank sub-categories by profit within each region (window function: RANK)
SELECT * FROM (
    SELECT
        region,
        sub_category,
        ROUND(SUM(profit), 2) AS total_profit,
        RANK() OVER (PARTITION BY region ORDER BY SUM(profit) DESC) AS profit_rank
    FROM orders
    GROUP BY region, sub_category
) ranked
WHERE profit_rank <= 3
ORDER BY region, profit_rank;

-- 9. Customer segment performance
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS avg_sales_per_customer
FROM orders
GROUP BY segment
ORDER BY total_sales DESC;

-- 10. Top 10 customers by total spend (repeat buyers only)
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    ROUND(SUM(sales), 2) AS total_spend
FROM orders
WHERE customer_id IN (
    SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(*) > 5
)
GROUP BY customer_id
ORDER BY total_spend DESC
LIMIT 10;
