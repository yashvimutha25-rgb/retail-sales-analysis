-- Retail Sales Analysis: analysis queries (run after retail_sales_setup.sql)
-- Revenue = quantity * unit_price * (1 - discount)

-- Q1. Headline KPIs
SELECT COUNT(*) AS total_orders,
       SUM(quantity) AS units_sold,
       ROUND(SUM(quantity*unit_price*(1-discount)),0) AS total_revenue,
       ROUND(SUM(quantity*unit_price*(1-discount))/COUNT(*),0) AS avg_order_value
FROM sales;

-- Q2. Revenue by category (JOIN + GROUP BY)
SELECT p.category,
       SUM(s.quantity) AS units,
       ROUND(SUM(s.quantity*s.unit_price*(1-s.discount)),0) AS revenue,
       ROUND(100.0*SUM(s.quantity*s.unit_price*(1-s.discount))/(SELECT SUM(quantity*unit_price*(1-discount)) FROM sales),1) AS revenue_share_pct
FROM sales s JOIN products p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Q3. Revenue by region
SELECT st.region, COUNT(*) AS orders,
       ROUND(SUM(s.quantity*s.unit_price*(1-s.discount)),0) AS revenue
FROM sales s JOIN stores st ON s.store_id = st.store_id
GROUP BY st.region
ORDER BY revenue DESC;

-- Q4. Top 10 products by revenue
SELECT p.product_name, p.category, SUM(s.quantity) AS units,
       ROUND(SUM(s.quantity*s.unit_price*(1-s.discount)),0) AS revenue
FROM sales s JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- Q5. Monthly revenue trend
SELECT SUBSTR(order_date,1,7) AS month,
       COUNT(*) AS orders,
       ROUND(SUM(quantity*unit_price*(1-discount)),0) AS revenue
FROM sales
GROUP BY SUBSTR(order_date,1,7)
ORDER BY month;

-- Q6. Month-over-month growth % (CTE + LAG window function)
WITH monthly AS (
  SELECT SUBSTR(order_date,1,7) AS month, SUM(quantity*unit_price*(1-discount)) AS revenue
  FROM sales GROUP BY SUBSTR(order_date,1,7)
)
SELECT month, ROUND(revenue,0) AS revenue,
       ROUND(100.0*(revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month),1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q7. Category x Region revenue (3-table JOIN, two GROUP BY columns)
SELECT p.category, st.region,
       ROUND(SUM(s.quantity*s.unit_price*(1-s.discount)),0) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY p.category, st.region
ORDER BY p.category, revenue DESC;

-- Q8. Best-selling product inside each category (RANK window function)
SELECT category, product_name, revenue FROM (
  SELECT p.category, p.product_name,
         ROUND(SUM(s.quantity*s.unit_price*(1-s.discount)),0) AS revenue,
         RANK() OVER (PARTITION BY p.category ORDER BY SUM(s.quantity*s.unit_price*(1-s.discount)) DESC) AS rnk
  FROM sales s JOIN products p ON s.product_id = p.product_id
  GROUP BY p.category, p.product_name
) t
WHERE rnk = 1;

-- Q9. Discount impact: average discount and revenue given away, by category
SELECT p.category,
       ROUND(100*AVG(s.discount),1) AS avg_discount_pct,
       ROUND(SUM(s.quantity*s.unit_price*s.discount),0) AS discount_value
FROM sales s JOIN products p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY avg_discount_pct DESC;

-- Q10. Quarterly revenue (CASE)
SELECT CASE WHEN SUBSTR(order_date,6,2) IN ('01','02','03') THEN 'Q1'
            WHEN SUBSTR(order_date,6,2) IN ('04','05','06') THEN 'Q2'
            WHEN SUBSTR(order_date,6,2) IN ('07','08','09') THEN 'Q3'
            ELSE 'Q4' END AS quarter,
       ROUND(SUM(quantity*unit_price*(1-discount)),0) AS revenue
FROM sales
GROUP BY 1
ORDER BY 1;

-- Q11. Repeat customers: top 10 by spend (HAVING)
SELECT customer_id, COUNT(*) AS orders,
       ROUND(SUM(quantity*unit_price*(1-discount)),0) AS total_spend
FROM sales
WHERE customer_id <> 'UNKNOWN'
GROUP BY customer_id
HAVING COUNT(*) >= 5
ORDER BY total_spend DESC
LIMIT 10;

-- Q12. Payment mode split
SELECT payment_mode, COUNT(*) AS orders,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM sales),1) AS pct_orders
FROM sales
GROUP BY payment_mode
ORDER BY orders DESC;
