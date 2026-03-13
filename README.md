# global-ecommerce-case-study
Case study using SQL with Google BigQuery and Tableau to explore success of different countries and marketing channels from theLook eCommerce data


# The Business Case

## Major Questions



## Major Solutions

### Tools

### Needed Data and Metrics
The Users table has information in 



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


# Data Visualization and Insights in Tableau


# Conclusion

## Summary of Main Insights

## Recommendations for Future Research
