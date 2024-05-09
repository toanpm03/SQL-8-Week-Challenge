# Data Cleaning

## Initial Cleaning:

### 1. Table: `customer_orders`

#### Original Table:
![image](https://user-images.githubusercontent.com/101379141/195287305-bce41c1a-8cab-475e-98c0-f3f64786bd39.png)

#### Changes:
- Changing all the NULL and 'null' to blanks
- Creating a clean temp table 

```sql
DROP TABLE IF EXISTS #customer_orders;
SELECT order_id, 
        customer_id,
        pizza_id, 
        CASE WHEN exclusions = '' OR exclusions like 'null' THEN NULL
            ELSE exclusions END AS exclusions,
        CASE WHEN extras = '' OR extras like 'null' THEN NULL
            ELSE extras END AS extras, 
        order_time
INTO #customer_orders -- create TEMP TABLE
FROM customer_orders;
```
#### Cleaned table:
![image](https://user-images.githubusercontent.com/101379141/195287781-927b309c-14ec-4f64-ae00-e76d34c88be5.png)

#
### 2. Table: `runner_orders`

#### Original Table:
![image](https://user-images.githubusercontent.com/101379141/195288132-fee8e31e-d19e-462b-88ce-f6129982b269.png)

#### Changes:
- Changing all the NULL and 'null' to blanks for strings
- Changing all the 'null' to NULL for non strings
- Removing 'km' from distance
- Removing anything after the numbers from duration
- Creating a clean temp table 

```sql
DROP TABLE IF EXISTS #runner_orders
SELECT  order_id, 
        runner_id,
        CASE 
          WHEN pickup_time LIKE 'null' THEN NULL
          ELSE pickup_time 
          END AS pickup_time,
        CASE 
          WHEN distance LIKE 'null' THEN NULL
          WHEN distance LIKE '%km' THEN TRIM('km' from distance) 
          ELSE distance END AS distance,
        CASE 
          WHEN duration LIKE 'null' THEN NULL 
          WHEN duration LIKE '%mins' THEN TRIM('mins' from duration) 
          WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)        
          WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)       
          ELSE duration END AS duration,
        CASE 
          WHEN cancellation LIKE 'null' THEN NULL
          WHEN cancellation = '' THEN NULL
          ELSE cancellation END AS cancellation
INTO #runner_orders
FROM runner_orders;
```
#### Cleaned Table:
![image](https://user-images.githubusercontent.com/101379141/195291586-76484f29-f489-479d-a070-341ffce6783d.png)

# 
### 3. Changing data types
- For #runner_orders table:
  - Change pickup_time DATETIME
  - Change distance to FLOAT
  - Change duration to INT
- For pizza_names table:
  - Change pizza_name to VARCHAR(MAX)
- For pizza_recipes table:
  - Change toppings to VARCHAR(MAX)
- For pizza_toppings table:
  - Change topping_name to VARCHAR(MAX)
```sql
ALTER TABLE #runner_orders 
ALTER COLUMN pickup_time DATETIME

ALTER TABLE #runner_orders
ALTER COLUMN distance FLOAT

ALTER TABLE #runner_orders
ALTER COLUMN duration INT;

ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(MAX);

ALTER TABLE pizza_recipes
ALTER COLUMN toppings VARCHAR(MAX);

ALTER TABLE pizza_toppings
ALTER COLUMN topping_name VARCHAR(MAX)
```
# A. Pizza Metrics Solutions

## Questions

### 1. How many pizzas were ordered?

```sql
SELECT count(order_id) as total_pizza_ordered
FROM #customer_orders;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195295105-d313039e-8054-49ff-a1f5-059d785734c5.png)

#
### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) as unique_orders
FROM #customer_orders
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195295267-96f0c3b8-e7d5-441b-975c-3a4e36870cf3.png)
#
### 3. How many successful orders were delivered by each runner?

```sql
SELECT runner_id,
       COUNT(runner_id) AS successful_orders
FROM #runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195295640-95029d36-5e77-4a5f-9939-1e250b459d2a.png)

#
### 4. How many of each type of pizza was delivered?


```sql
SELECT pizza_id, 
       COUNT(pizza_id) as amount_of_dilivered_pizza
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS null
GROUP BY pizza_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195296832-dcd57890-0c22-445e-84f7-c3c179779151.png)

#
### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT customer_id,
        P.pizza_name, 
        COUNT(c.pizza_id) as amount_pizza
FROM #customer_orders c 
INNER JOIN pizza_names p ON c.pizza_id =p.pizza_id
GROUP BY customer_id,pizza_name
ORDER BY customer_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195297281-1cce363d-8988-4b0d-ab89-ac83ce1465aa.png)

#
### 6. What was the maximum number of pizzas delivered in a single order?
- Here we want the max number of pizzas `delivered` in a single order.
  - So we need a `WHERE` clause to filter only orders where `pickup_time IS NOT NULL` (order was not cancelled).
- Then we can use `SELECT TOP 1`, and `ORDER by the COUNT of pizza_id in DESCENDING order` (largest count first) to get the max count of pizzas delivered.

```sql
SELECT TOP 1 c.order_id, 
       COUNT(c.order_id) as number_order
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY c.order_id
ORDER BY number_order DESC;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195298260-4a37c6e3-312b-447b-affd-b926a541831d.png)

#
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
- In this case, I use CTE, and CASE WHEN method to create a new column 'STATUS'  

```sql
WITH Status_table AS (
            SELECT order_id, 
                    customer_id,
                    pizza_id,
                    exclusions, 
                    extras, 
                    CASE WHEN exclusions is not null or extras is not null THEN 'CHANGE'
                      ELSE 'NOT CHANGE' END AS STATUS 
            FROM #customer_orders 
)
SELECT customer_id,
        STATUS, 
        COUNT(STATUS) as count
FROM Status_table s 
RIGHT JOIN #runner_orders r ON s.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id,STATUS
ORDER BY customer_id

```
#### Results
![image](https://user-images.githubusercontent.com/101379141/195299842-736cfa8d-ba7a-468a-b0f2-792cf0a4ab66.png)

#
### 8. How many pizzas were delivered that had both exclusions and extras?
- This is when `both fields` in the exclusions and extras columns `are populated`, so not NULL .
- Again, we want delivered pizzas so we need the same WHERE clause as before.

```sql
SELECT count(c.order_id) as both_exclusions_extras
FROM #customer_orders c 
RIGHT JOIN #runner_orders r ON c.order_id = r.order_id
WHERE exclusions is not null and extras is not null and r.cancellation is null
```
#### Results
![image](https://user-images.githubusercontent.com/101379141/195300360-72d19b1c-4b0c-4d24-bbca-95341cbff68a.png)

#
### 9. What was the total volume of pizzas ordered for each hour of the day?
- Here we can use `DATEPART` to `extract the HOUR from order_date`.
  - Using `DATENAME`would give us the same result.
    - The difference is DATEPART returns an intiger, while DATENAME returns a string.
  
```sql
SELECT DATEPART(HOUR, [order_time]) as hour_of_day, 
       COUNT (order_id) as pizza_count
FROM #customer_orders
GROUP BY DATEPART(HOUR, [order_time])
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195300844-f31063c1-dbca-404d-b4c3-647f744f3bca.png)

#
### 10. What was the volume of orders for each day of the week?
- Here we can use `DATENAME` to `extract the WEEKDAY with their actual names (Monday, Tuesday...)` instead of numbers (1, 2...) from order_time.
  
```sql
SELECT DATENAME(WEEKDAY,[order_time]) as weekday, 
        COUNT (order_id) as pizza_count
FROM #customer_orders
GROUP BY DATENAME(WEEKDAY,[order_time]);

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195301182-58d957a6-6cd1-4c37-9b96-dc332a7e5f4d.png)

# B. Runner and Customer Experience Solutions

## Questions

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SET DATEFIRST 1; --Set Monday is the first day of week

SELECT DATEPART(WEEK,[registration_date])as week, 
        COUNT(runner_id) as runner_count 
FROM runners
GROUP BY DATEPART(WEEK,[registration_date]);
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195483753-fa8e56b1-a7b9-4630-95ab-0192ea537d74.png)

#
### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
- We create a time column through a CTE.
  - We can use `DATEDIFF` to find the difference between order_time and pickup_time in `MINUTES`
  - The CAST's were used to transform the numbers into FLOAT and to be able to round the numbers correctly. Doing it with ROUND wasn't working.  
 
```sql
WITH time_table AS (SELECT DISTINCT runner_id, 
                             r.order_id,
                             order_time, 
                             pickup_time, 
                             CAST(DATEDIFF( minute,order_time,pickup_time) AS FLOAT) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
                )

SELECT runner_id, AVG(time)  AS average_time
FROM time_table
GROUP BY runner_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195485007-ff58fe67-e4ab-420e-9fd2-a22fa48ad99e.png)

- Runner 1's average is 14 mins 
- Runner 2's average is 20 mins 
- Whilst runner 3's average is 10 mins 

#
### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
WITH CTE AS (SELECT  c.order_id,
                      COUNT(c.order_id) as pizza_order,
                      order_time, pickup_time, 
                      CAST(DATEDIFF( minute,order_time,pickup_time) AS FLOAT) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
GROUP BY  c.order_id,order_time, pickup_time)


SELECT pizza_order,
        AVG(time) AS avg_time_per_order, 
        (AVG(time)/ pizza_order) AS avg_time_per_pizza
FROM CTE
GROUP BY pizza_order

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486114-74b55689-b82b-4cf4-952e-68bf6fb20030.png)

- Here we can see that as the number of pizzas in an order goes up, so does the total prep time for that order, as you would expect.
- But then we can also notice that the average preparation time per pizza is higher when you order 1 than when you order multiple. 

#
### 4. What was the average distance travelled for each customer?

```sql
SELECT customer_id, 
        AVG(distance) AS Average_distance
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486333-42721bfb-ab1f-43aa-9817-0f4f779aa915.png)

#
### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT  max(duration) as longest,
        min(duration) as shortest,
        max(duration) - min(duration) as dif_longest_shortest
FROM #runner_orders
WHERE cancellation is NULL
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486569-ba6b2f60-e067-4b79-b7e0-0c1ad862e5e0.png)

- The difference between the longest and shortest delivery was 30 mins. 

#
### 6. What was the average speed for each runner for each delivery?
- Let's see the `speed for each runner for each delivery`:

```sql
SELECT runner_id, 
        order_id, 
        ROUND(AVG(distance/duration*60),2) as avg_time
FROM #runner_orders
WHERE cancellation is NULL 
GROUP BY runner_id,order_id
ORDER BY runner_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195486740-c42f2d32-b7e2-47b4-878c-f6865d6531e4.png)
- Now let's see the `average speed for each runner in total`: 



#
### 7. What is the successful delivery percentage for each runner?

```sql
with CTE AS (SELECT runner_id, order_id,
      CASE WHEN cancellation is NULL THEN 1
        ELSE 0 END AS Sucess_delivery
FROM #runner_orders)
SELECT runner_id, round( 100*sum(sucess_delivery)/count(*),0) as success_perc
FROM CTE
group by runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195487013-4620bbfd-5150-4e20-9ef9-0e2a210c8efb.png)

# C. Ingredient Optimisation Solutions

## Contents:
- [Data Cleaning Solutions](#data-cleaning-for-this-section)
- [Question Solutions](#questions)

## Data Cleaning for this section 
### 1. Table: `#pizza_recipes`

#### Original table:
![image](https://user-images.githubusercontent.com/94410139/158227609-4fd32726-4918-4368-918b-c81aa48045db.png)

#### Changes:
- Splitting comma delimited lists into rows
- Creating a clean temp table 

```sql
DROP TABLE IF EXISTS #pizza_recipes;
SELECT pizza_id, 
        TRIM(topping_id.value) as topping_id,
        topping_name
INTO #pizza_recipes
FROM pizza_recipes p
CROSS APPLY string_split(p.toppings, ',') as topping_id
INNER JOIN pizza_toppings p2 ON TRIM(topping_id.value) = p2.topping_id
```
#### New table:
![image](https://user-images.githubusercontent.com/101379141/195526923-428d7053-1021-45f2-9c7d-e96141441627.png)

## Data Cleaning for question 4-5
### 2. Table: `#customer_orders` 

#### Original table: 
![image](https://user-images.githubusercontent.com/101379141/195491823-727ed58b-1eb7-4d7c-874d-569d9e55de5d.png)

#### Changes:
- Adding an Identity Column (to be able to uniquely identify every single pizza ordered) 

```sql
ALTER TABLE #customer_orders
ADD record_id INT IDENTITY(1,1)
```
![image](https://user-images.githubusercontent.com/101379141/195491565-90847021-72a6-445b-b92a-8cbef9114f67.png)

#
### 3. New Tables: `Exclusions` & `Extras` 

#### Changes:
- Splitting the exclusions & extras comma delimited lists into rows and storing in new tables

#### New Extras Table:
```sql
DROP TABLE IF EXISTS #extras
SELECT		
      c.record_id,
      TRIM(e.value) AS topping_id
INTO #extras
FROM #customer_orders as c
	    CROSS APPLY string_split(c.extras, ',') as e;
```
![image](https://user-images.githubusercontent.com/101379141/195492588-dc9a3348-61b8-4802-93c1-2188a6c1e717.png)

#### New Exclusions Table:
```sql
DROP TABLE IF EXISTS #exclusions
SELECT	c.record_id,
	      TRIM(e.value) AS topping_id
INTO #exclusions
FROM #customer_orders as c
	    CROSS APPLY string_split(c.exclusions, ',') as e;
```
![image](https://user-images.githubusercontent.com/101379141/195492431-73671fdb-df6e-45b2-b890-708c629547b2.png)
#
## Questions
### 1. What are the standard ingredients for each pizza?
- We can use `STRING_AGG()` to create a comma delimited list of the topping names.

```sql
WITH CTE AS (
              SELECT pizza_id, 
                      topping_name
              FROM #pizza_recipes p1
              INNER JOIN pizza_toppings p2 
              ON p1.topping_id = p2.topping_id
)
SELECT pizza_id, String_agg(topping_name,',') as Standard_toppings
FROM CTE
GROUP BY pizza_id;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195527944-fcd3b9c0-1d5b-46a2-b553-ea22945251d6.png)
#
### 2. What was the most commonly added extra?
- We use CTE, Subqueries, Unpivot method in this question:
  - In CTE, we use SUBSTRING to split topping to different column
  - Use UNPIVOT, to transfer table to multi-index column style to ordinary style


```sql
WITH CTE AS (SELECT pizza_id,
                    topping_type,
                    topping
FROM (SELECT pizza_id, 
              CAST(SUBSTRING(extras, 1,1) AS INT) AS topping_1, 
              CAST(SUBSTRING(extras,3,3) AS INT) as topping_2
      FROM #customer_orders
      WHERE extras is not null) p 
      UNPIVOT (topping for topping_type in (topping_1,topping_2)) as unpvt)

SELECT Topping, 
        topping_name, 
        COUNT(topping) AS Extra_Topping_Time
FROM CTE c
JOIN pizza_toppings p ON c.topping = p.topping_id
WHERE topping != 0
GROUP BY topping,topping_name;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195490789-74758669-b84c-43ed-82f7-b766633cdf78.png)

- The most common added : Bacon

#
### 3. What was the most common exclusion?
- Same as the question above but using the `COUNT of exclusions_id`.

```sql
WITH CTE AS (SELECT pizza_id,
                    topping_type,
                    topping
              FROM (SELECT pizza_id, 
                            CAST(SUBSTRING(exclusions, 1,1) AS INT) AS exclusions_1, 
                            CAST(SUBSTRING(exclusions,3,3) AS INT) as exclusions_2
              FROM #customer_orders
              WHERE exclusions is not null) p 
              UNPIVOT (topping for topping_type in (exclusions_1,exclusions_2)) as unpvt)

SELECT Topping, 
        topping_name,
        count(topping) AS exclusions_Topping_Time
FROM CTE c
JOIN pizza_toppings p ON c.topping = p.topping_id 
WHERE topping != 0
GROUP BY topping,topping_name
ORDER BY exclusions_Topping_Time DESC;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195491147-47364099-7995-4adb-8ebb-914b72930724.png)
- The most common exclusion topping is Cheese
#

#
### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


#### Explanation
- What this question is asking is for you to create a column in the customer_orders table where, for every record, it tells you the name of the pizza ordered as well as the names of any toppings added as extras or exclusions.

#### One way to achieve this
- Create `3 CTEs`: One for exclusions and one for extras and one for union (extras and exclusions).
  - We want to know what was excluded or added to each pizza.
  - In these CTEs we are going to SELECT the record_id (The unique identifier for every pizza ordered, [that we created in the data cleaning section](#2-table-customer_orders)) and the topping_name for those extras or exclusions.
    - We are using `STRING_AGG` to show those topping names in a comma delimited list (as that is how we need them in the final output).
    
- In the `final SELECT Statement` we are going to want to SELECT record_id,order_id in the customer_orders table and CONCAT(pizza name,  record_optionss) .
  - This is the example of the output we want to replicate with the CASE Statement:
  
     ```sql 
        - Meat Lovers
        - Meat Lovers - Exclude Beef
        - Meat Lovers - Extra Bacon
        - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
     ```
  - `  

```sql
with extras_cte AS (
                    SELECT 
                      record_id,
                      'Extra ' + STRING_AGG(t.topping_name, ', ') as record_options
                    FROM #extras e,
                         pizza_toppings t
                    WHERE e.topping_id = t.topping_id
                    GROUP BY record_id
                    ),
exclusions_cte AS
                  (
                    SELECT 
                      record_id,
                      'Exclude ' + STRING_AGG(t.topping_name, ', ') as record_options
                    FROM #exclusions e,
                         pizza_toppings t
                    WHERE e.topping_id = t.topping_id
                    GROUP BY record_id
                  ),
union_cte AS
                  (
                    SELECT * FROM extras_cte
                    UNION
                    SELECT * FROM exclusions_cte
                  )

SELECT c.record_id, 
        c.order_id,
        CONCAT_WS(' - ', p.pizza_name, STRING_AGG(cte.record_options, ' - ')) as pizza_and_topping
FROM #customer_orders c
JOIN pizza_names p ON c.pizza_id = p.pizza_id
LEFT JOIN union_cte cte ON c.record_id = cte.record_id
GROUP BY
	c.record_id,
	p.pizza_name,
  c.order_id
ORDER BY 1;
```
#### exclusions CTE output
![image](https://user-images.githubusercontent.com/101379141/195494327-ab4a5f84-5c32-4d32-b43f-def828ac42b3.png)

#### extras CTE output
![image](https://user-images.githubusercontent.com/101379141/195494364-1f1086cb-efe9-42c1-bf97-af743424040b.png)

#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195494415-4803a537-18e6-42fb-848d-37427ca929e7.png)

#
### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


#### Explanation
- Here we want to create a new column in the customer_orders table in which it tells us, for each record, the pizza name as well as a list of the ingredients to use. 
- In the ingredient list we want to exclude the toppings the customer excluded (we dont want them to appear on the list) and add a '2x' infront of the toppings the customer added as extras. 

#### One way to achieve this
- we add topping name ino pizza_recipe and Use CASE WHEN to indentify and 2x with relevant ingredient ( if they are in #extras table)


#### new #pizza_recipes table 
![image](https://user-images.githubusercontent.com/101379141/195495321-abe45c47-fa69-49de-ba7e-87ef6465ab67.png)

```sql
WITH INGREDIENT_CTE AS (SELECT record_id,
                                pizza_name,
                                CASE WHEN p1.topping_id in (
                                                  SELECT topping_id
                                                  FROM #extras e
                                                  WHERE C.record_id = e.record_id
                                                 ) 
                                      THEN '2x' + p1.topping_name
                                      ELSE p1.topping_name
                                      END AS topping
                        FROM #customer_orders c 
                        JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
                        JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
                        WHERE p1.topping_id NOT IN (SELECT topping_id 
                                                 FROM #exclusions e 
                                                 WHERE e.record_id = c.record_id)
                      )

SELECT record_id, 
      CONCAT(pizza_name +':' ,STRING_AGG(topping, ',' ) WITHIN GROUP (ORDER BY topping ASC)) AS ingredient_list
FROM INGREDIENT_CTE
GROUP BY  record_id,pizza_name
ORDER BY 1;
```
#### the ingredients CTE output
![image](https://user-images.githubusercontent.com/101379141/195495773-6084c212-914a-4443-a103-b7c7f00ea784.png)
#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195495709-0951043d-ebb1-4c39-b4db-c238cf2adc10.png)
#
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

#### Explanation
- Here we want a list of the all the ingredients and a SUM of how many times each one has been used, in DESCENDING order (most used first).

#### One way to achieve this
- Create a `CTE`:
- In this CTE we are going to SELECT the record_id, the pizza_name, the topping_name, create a CASE Statement to show the times every ingredient was used in each pizza.
  - The `CASE Statemet`:
    - We want to generate a column (I called it times_used_topping) 
      - CASE WHEN the topping (topping_id) is found IN the extras_id column in the #extras table WHERE the records are the same
      - THEN return 2
      - ELSE return 1
   - We also include WHERE statement to eliminate 'excluded topping', cancelled pizza
- In the `final SELECT Statement`:
  - SELECT the topping_name
  - And a SUM of the topping_times_used
  - ORDER BY the topping_times_used in DESCENDING order (most frequently used first)

```sql
WITH INGREDIENT_CTE AS (SELECT record_id,
                                pizza_name, 
                                topping_name,
                                CASE WHEN p1.topping_id in (
                                  SELECT topping_id
                                  FROM #extras e
                                  WHERE C.record_id = e.record_id
                                ) THEN 2
                                ELSE 1
                                END AS times_used_topping
                        FROM #customer_orders c 
                        JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
                        JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
                        JOIN #runner_orders r ON c.order_id = r.order_id
                        WHERE p1.topping_id NOT IN (SELECT topping_id 
                                                  FROM #exclusions e 
                                                  WHERE e.record_id = c.record_id) 
                                                  and r.cancellation is NULL
                         )

SELECT topping_name, 
        SUM(times_used_topping) AS times_used_topping
from INGREDIENT_CTE
GROUP BY topping_name
order by times_used_topping desc;

SELECT topping_name, 
        SUM(times_used_topping) AS times_used_topping
from INGREDIENT_CTE
GROUP BY topping_name
order by times_used_topping desc;
```
#### Fragment of ingredients CTE
![image](https://user-images.githubusercontent.com/101379141/195499293-117f860d-c191-4243-9b72-5a224317a170.png)
#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195500818-de57476b-78e3-445d-a985-d10e4504fdca.png)

# D. Pricing and Ratings Solutions

#
## Questions

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
- Here we will want to use a CTE method with a CASE Statement .
    - CASE WHEN the pizza name is Meatlovers 
    - THEN add 12 (dollars)
    - ELSE add 10
  
- SUM pizza_cost in the next SELECT.
    
```sql
WITH CTE AS (SELECT pizza_id, 
                    pizza_name,
                    CASE WHEN pizza_name = 'Meatlovers' THEN 12
                      ELSE 10 END AS pizza_cost
             FROM pizza_names) 

SELECT SUM(pizza_cost) as total_revenue
FROM #customer_orders c 
JOIN #runner_orders r ON c.order_id = r.order_id
JOIN CTE c2 ON c.pizza_id = c2.pizza_id
WHERE r.cancellation is NULL;
```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195514689-cd40ad60-0e94-4256-8dd9-ff2e3954a5af.png)
#
### 2. What if there was an additional $1 charge for any pizza extras? (Add cheese is $1 extra)

#### One way to do this
- Here we need to create a `CTE`:
  - This CTE will show the inital price of each pizza (each record_id) and type of topping extras and exclusions.
    - In it we need to SELECT the exclusion,extras and build CASE Statements to list pirce of pizza.
  
- In the `final SELECT Statement`:
  - we are going to add SUM of CASE Statement  initial_price + pizza_topping extras cost

```sql
WITH pizza_cte AS
          (SELECT 
                  (CASE WHEN pizza_id=1 THEN 12
                        WHEN pizza_id = 2 THEN 10
                        END) AS pizza_cost, 
                  c.exclusions,
                  c.extras
          FROM #runner_orders r
          JOIN #customer_orders c ON c.order_id = r.order_id
          WHERE r.cancellation IS  NULL
          )
SELECT 
      SUM(CASE WHEN extras IS NULL THEN pizza_cost
               WHEN DATALENGTH(extras) = 1 THEN pizza_cost + 1
               ELSE pizza_cost + 2
                END ) AS total_earn
FROM pizza_cte;
```
#### pizza CTE output
![image](https://user-images.githubusercontent.com/101379141/195516580-b7641187-9215-460e-96a4-0742e8cea89d.png)

#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195516682-f3441803-17a9-4012-9ff6-21d272cf1e65.png)
#
### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
DROP TABLE IF EXISTS ratings
CREATE TABLE ratings 
 (order_id INTEGER,
    rating INTEGER);
INSERT INTO ratings
 (order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5); 

SELECT * 
from ratings


```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195516961-88a7bf3d-a07f-4bec-b81b-7d75fb69f2ae.png)
#
### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? 
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

```sql
SELECT customer_id , 
        c.order_id, 
        runner_id, 
        rating, 
        order_time, 
        pickup_time, 
        datepart( minute,pickup_time - order_time) as Time__order_pickup, 
        r.duration, 
        round(avg(distance/duration*60),2) as avg_Speed, 
        COUNT(pizza_id) AS Pizza_Count
FROM #customer_orders c
LEFT JOIN #runner_orders r ON c.order_id = r.order_id 
LEFT JOIN ratings r2 ON c.order_id = r2.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id , c.order_id, runner_id, rating, order_time, pickup_time, datepart( minute,pickup_time - order_time) , r.duration
ORDER BY c.customer_id;

```
#### Result
![image](https://user-images.githubusercontent.com/101379141/195517205-b1c78ce7-47aa-46b4-9bf9-8e551ead209d.png)
#
### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

#### One way to achieve this 
- Here we are going to create `CTE`:
  - We want this table to show the order_id, how much the pizzas cost per order
- Then in the `final SELECT Statement`:
  - We want to SUM the revenue made from the pizzas
  - SUM all distance * 0.3  that was paid to the runners
  - and take that runner_cost away from the pizza_revenue to give us the profit gained
 
```sql
WITH CTE AS (SELECT c.order_id,
                    SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12
                          ELSE 10 END) AS pizza_cost
             FROM pizza_names p
             JOIN #customer_orders c ON p.pizza_id =c.pizza_id
             GROUP BY c.order_id) 

SELECT SUM(pizza_cost) AS revenue, 
       SUM(distance) *0.3 as total_cost,
       SUM(pizza_cost) - SUM(distance)*0.3 as profit
FROM #runner_orders r 
JOIN CTE c ON R.order_id =C.order_id
WHERE r.cancellation is NULL
```
####  CTE output
![image](https://user-images.githubusercontent.com/101379141/195524663-0c1e08a7-2588-466b-9bba-3fb6831938f2.png)
#### Final Result
![image](https://user-images.githubusercontent.com/101379141/195524723-407b3ff2-4337-452a-a273-c3d7f5f05bbb.png)
