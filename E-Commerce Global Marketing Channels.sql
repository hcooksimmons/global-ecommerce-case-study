-- Step 1: Get customer information from the Users table - id, country, source of marketing channel traffic and make sure to clean the country name data to standard English spelling
WITH users AS (
SELECT
  id AS user_id,

  CASE
    WHEN country = 'Deutschland' THEN 'Germany'
    WHEN country = 'Brasil' THEN 'Brazil'
    WHEN country = 'España' THEN 'Spain'
    ELSE country
  END AS country,

  traffic_source AS marketing_channel

FROM `bigquery-public-data.thelook_ecommerce.users`
),

-- Step 2: Get information about users' orders, date, revenue from Order_items filtered by completed orders only
orders AS (
SELECT
  user_id,
  order_id,
  DATE(created_at) AS order_date,
  SUM(sale_price) AS order_revenue
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE status = 'Complete'
GROUP BY
  user_id,
  order_id,
  order_date
),

-- Step 3: Find each customer's first completed purchase out of the previous step's order information
first_purchase AS (
SELECT
  user_id,
  MIN(order_date) AS first_purchase_date
FROM orders
GROUP BY user_id
),

-- Step 4: Calculate revenue and purchases per customer, and the 6 month LTV of the customer
customer_metrics AS (
SELECT
  orders.user_id,

  SUM(orders.order_revenue) AS total_revenue,

  SUM(
    CASE
      WHEN orders.order_date <= DATE_ADD(first_purchase.first_purchase_date, INTERVAL 6 MONTH)
      THEN orders.order_revenue
      ELSE 0
    END
  ) AS six_month_ltv,

  COUNT(DISTINCT orders.order_id) AS purchase_count

FROM orders
JOIN first_purchase
ON orders.user_id = first_purchase.user_id

GROUP BY orders.user_id
)

-- Step 5: Final table grouped by country and marketing channel showing the locations and marketing channels that have generated the highest revenue with average 6 month LTV also included
SELECT
  users.country,
  users.marketing_channel,

  COUNT(DISTINCT customer_metrics.user_id) AS customers,

  SUM(customer_metrics.total_revenue) AS total_revenue,

  AVG(customer_metrics.six_month_ltv) AS avg_6_month_ltv,

  SAFE_DIVIDE(
    COUNTIF(customer_metrics.purchase_count > 1),
    COUNT(DISTINCT customer_metrics.user_id)
  ) AS retention_rate

FROM customer_metrics
JOIN users
ON customer_metrics.user_id = users.user_id

GROUP BY
  users.country,
  users.marketing_channel

ORDER BY
  total_revenue DESC