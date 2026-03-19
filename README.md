# global-ecommerce-case-study
Case study using SQL with Google BigQuery and Tableau to explore success of different countries and marketing channels from The Look eCommerce data


# The Business Case
ECommerce companies such as the fictional The Look eCommerce clothing website must make decisions about what marketing channels (including search ads, email campaigns, and social media) they should use to attract customers that will bring the most revenue over time. In this scenario, I decided to help The Look determine which countries are the key markets, and whether TheLook needs to focus on different marketing channels for different countries. After my analysis, I am able to make recommendations to TheLook on where to direct its marketing budget to channels in country locations that will maximize revenue, customer retention, and six-month customer lifetime value (LTV).


## Major Questions
Which country markets and which marketing channels bring the most valuable and loyal customers?

For customer value by country and/or marketing channel, we will want to look not only at the total revenue brought by customers in each country/marketing channel, but also at how customers are generating value over time, as measured by the average six-month customer lifetime value (LTV) for each country/marketing channel. We will also look at the loyalty of customers through the retention rate as what percentage of customers per country/marketing channel are making repeat purchases.


### Tools
- SQL in Google BigQuery: data cleaning, final data table for analysis
- Tableau Public: For analysis and display of results


### Needed Data
[The Look eCommerce data] (https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce?hl=es&project=the-look-data) contains multiple tables about products, orders, distribution, and customers, only some of which were needed for this project. 

| Tables Used  | Fields Used | Description |
| ------------- | ------------- | ------------ |
| Users  | id, country, traffic_source  | Information about every customer including user id for every customer to count unique amount of customers, customer country, source of marketing channel traffic |
| Order_items  | user_id, order_id, created_at, sales_price  | Information about every item ordered including customer's user id, unique id for every order, date of order creation, and the sales price of the item used for the revenue of the item ordered |
| Orders  | order_id  | Unique id for every order used to confirm lack of duplicate orders |



# Data Cleaning in SQL with BigQuery

## Checking for Duplicates, Null Values, and Non-Standard Entries
First, I ran some SQL code to check for duplicates, null values, and non-standard entries in the specific fields that I needed to construct my final table. This checking step allowed me to know what data cleaning measures I needed to include in the code to create my final data table. While there were no missing entries (null values) or duplicate entries for the the part of the data that I needed, I did discover that some of the country names were entered both with the English spelling and the country name for the local language, so those needed to be merged and standardized later on.

**Data Cleaning Check 1: I checked the `users` table for missing Values in `id`, `country`, and `traffic_source`**
```SQL
SELECT 
  COUNT(*) AS total_rows,
  SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS missing_user_id,
  SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS missing_country,
  SUM(CASE WHEN traffic_source IS NULL THEN 1 ELSE 0 END) AS missing_marketing_channel,
FROM `bigquery-public-data.thelook_ecommerce.users`;
```
No missing values detected.



**Data Cleaning Check 2: I checked the `users` table for non-standard entries in the `country` field**
```SQL
SELECT DISTINCT country
FROM `bigquery-public-data.thelook_ecommerce.users`
ORDER BY country;
```
Brazil was all spelled as 'Brasil' in Portuguese, Germany was occasionally entered as 'Deutschland', and one entry for Spain was 'España'.



**Data Cleaning Check 3: I checked `traffic_source` in the `users` table to see if there were any unexpected entries in the users' marketing channels**
```SQL
SELECT DISTINCT traffic_source
FROM `bigquery-public-data.thelook_ecommerce.users`
ORDER BY traffic_source;
```
No errors detected.



**Data Cleaning Check 4: I checked the `users` table for duplicate customers using the users' `id`**
```SQL
SELECT id, COUNT(*) AS count
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY id
HAVING COUNT(*) > 1;
```
No duplicates detected.



**Data Cleaning Check 5: I checked the `order_items` table for missing values in the order ID, user ID, date, and revenue**
```SQL
SELECT 
  COUNT(*) AS total_rows,
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS missing_user_id,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS missing_date,
  SUM(CASE WHEN sale_price IS NULL THEN 1 ELSE 0 END) AS missing_revenue
FROM `bigquery-public-data.thelook_ecommerce.order_items`;
```
No missing values detected.


**Data Cleaning Check 6: I checked the `orders` table for duplicate orders**
```SQL
SELECT order_id, COUNT(*) AS count
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY order_id
HAVING COUNT(*) > 1
```
No duplicates detected.



## Data Cleaning for Non-Standard Country Names
Because I uncovered some non-standard country names during my prior checks to see what data cleaning would be needed, I built some code to clean the country names into my SQL code.

Instead of selecting the country field with a standard `SELECT` statement that would bring all the errors in the data into my final table
```SQL
SELECT country
```

I made a `CASE` statement to use instead of `SELECT` that replaces all of the non-standard entries with the correct text for Germany instead of Deutschland, Brazil instead of Brasil, and Spain instead of España.
```SQL
  CASE
    WHEN country = 'Deutschland' THEN 'Germany'
    WHEN country = 'Brasil' THEN 'Brazil'
    WHEN country = 'España' THEN 'Spain'
    ELSE country
  END AS country,
```


# Generating a Data Table in SQL with BigQuery
**Step 1**

I got the customer information from the Users table (id, country, source of marketing channel traffic), while making sure to clean the country name data to standard English spellings
```SQL
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
```


**Step 2**

I got information about users' orders, order dates, and order revenue from the Order_items table, and I made sure to filter it by completed orders only so that our definition of customer is a user who has had at least one completed order, and our customer retention later on will only look at completed additional orders and not count those that were cancelled.
```SQL
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
```


**Step 3**

I found the date of each customer's first completed purchase out of the previous step's order information, which I used later on in the 6 month LTV calculation.
```SQL
first_purchase AS (
SELECT
  user_id,
  MIN(order_date) AS first_purchase_date
FROM orders
GROUP BY user_id
),
```

**Step 4**

I calculated the total revenue for each customer from all of their orders,  the 6 month LTV of the customer (defined as the revenue generated by the customer for all orders within six months from the customer's first purchase), and the total number of orders for the customer.
```SQL
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
```

**Step 5** 

Lastly, I created the final table grouped by country and marketing channel showing the locations and marketing channels that have generated the highest revenue with average 6 month LTV also included.
```SQL
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
```


  
# Data Visualization and Insights in Tableau
I built a [dashboard] (https://public.tableau.com/app/profile/haley.cook.simmons/viz/GlobalMarketingInsightsfromTheLookEcommerceData/GlobalMarketingDashboard_1/) on Tableau Public
Average 6-Month LTV vs. Retention Rate
Revenue by Marketing Channel



# Conclusion

## Summary of Main Insights

Search is the top marketing channel Out of the top ten customer segments for revenue by country and marketing channel

## Recommendations for Future Research
