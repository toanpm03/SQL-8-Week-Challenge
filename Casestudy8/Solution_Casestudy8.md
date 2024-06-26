# A. Data Exploration and Cleansing

###
**1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month**

```sql
UPDATE interest_metrics
SET month_year = CONVERT(date, '01-' + month_year,105)

ALTER TABLE interest_metrics
ALTER COLUMN month_year DATE 

```

    Output (first 5 rows):

![image](https://user-images.githubusercontent.com/101379141/200456465-476c11d4-e4c4-45e0-a3af-71a868f6bd35.png)


**2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?**

 ```sql
SELECT  month_year ,
        COUNT( *) AS total_record
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year  ;
 ```

 ![image](https://user-images.githubusercontent.com/101379141/200456843-7614d8e3-afaf-40f1-ae94-59e70fcb25d5.png)


**3. What do you think we should do with these `null` values in the `fresh_segments.interest_metrics`?**

- Dropping the rows where the month_year value is NULL could be the right things to do. 
  - Firstly, It contains 8 % of total values, it would not affect much to final result.
  - Secondly, Dropping Null values of month_year also drop the Null Values of other columns as (_month,_year,interest_id)

```sql
SELECT 100* COUNT(*) / (SELECT COUNT(*) FROM interest_metrics ) AS Percent_Null
FROM interest_metrics
WHERE month_year is NULL ;
```
![image](https://user-images.githubusercontent.com/101379141/200459187-2ffd5939-05ce-4f57-b977-7ff7a4a44535.png)


**4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?**

- `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map`



 ```sql
SELECT COUNT(interest_id) as Count_different_id
FROM interest_metrics 
WHERE interest_id not in (SELECT ID from interest_map) AND interest_id IS NOT NULL;
```

![image](https://user-images.githubusercontent.com/101379141/200458093-0ad89379-16b0-485b-9d07-a1fd0134a97b.png)

       

- `id` values exist in the `fresh_segments.interest_map` table but not in the `fresh_segments.interest_metrics`


 ```sql
SELECT ID
FROM interest_map 
WHERE ID not in (SELECT DISTINCT interest_id from interest_metrics WHERE interest_id IS NOT NULL);
```

![image](https://user-images.githubusercontent.com/101379141/200458175-28fe8ed2-079b-4b11-8363-7c2165defd22.png)


**5. Summarise the id values in the `fresh_segments.interest_map` by its total record count in this table**


```sql
SELECT COUNT(*) AS COUNT_ID  
FROM interest_map;
 ```

![image](https://user-images.githubusercontent.com/101379141/200458359-4712322e-4d29-4213-b9af-3f84fda742e8.png)

6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id = 21246` in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the `id` column.

- In my opinion, we should use left join between interest_metrics and interest_map table on interest_id . Because intrest_metrics is Fact Table and its interest_id need to be included in the final table to analyze to result

   

```sql
        SELECT mat.*
            ,map.interest_name
            ,map.interest_summary
            ,map.created_at
            ,map.last_modified
        FROM fresh_segments.interest_metrics AS mat
        LEFT JOIN fresh_segments.interest_map AS map
            ON mat.interest_id = map.id
        WHERE mat.interest_id = 21246;
```

![image](https://user-images.githubusercontent.com/101379141/200458538-7eca4f54-fa0b-4edf-82ee-f5f8a362fbbc.png)


7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the fresh_segments.`interest_map` table? Do you think these values are valid and why?


 ```sql
SELECT  Count(*)
FROM interest_metrics i1 
LEFT JOIN interest_map i2 ON i1.interest_id = i2.id 
WHERE month_year < created_at;
 ```

![image](https://user-images.githubusercontent.com/101379141/200458790-8bf00a1c-c4d1-4231-b984-9b645ff5ea19.png)

 
- There are total of 188 entries in the fresh_segments.interest_map table where the month_year value is before created_at value. this is valid because month_year column has been adjusted to the first day of the month in first question , they are represented as month and year of not exactly the date it created as created_at column in interest_map.

---
# B. Interest Analysis

**1. Which interests have been present in all `month_year` dates in our dataset?**


 ```sql
 SELECT  interest_name, 
        COUNT (month_year) AS TIME 
FROM interest_metrics i1
LEFT JOIN interest_map i2 ON i1.interest_id = i2.id 
WHERE month_year IS NOT NULL
GROUP BY  interest_name
HAVING COUNT(month_year) >= (SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
ORDER BY TIME DESC ;      
 ```

 ![image](https://user-images.githubusercontent.com/101379141/200459568-5fdabdc7-0b1a-4248-a04c-f267cc2e6160.png)


    <br/>

**2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?**


```sql
WITH ID_CTE AS (SELECT  interest_id , 
                        COUNT(DISTINCT month_year) as total_months
                FROM interest_metrics i1
                WHERE month_year IS NOT NULL
                GROUP BY interest_id),
Month_CTE AS (  SELECT total_months,
                        CAST (COUNT(DISTINCT interest_id) AS FLOAT) as interest_count
                FROM ID_CTE
                GROUP BY total_months)
SELECT  total_months,
        interest_count,
        FORMAT ( SUM(interest_count) OVER(ORDER BY total_months DESC  ) / SUM(interest_count) OVER(), 'P') AS cumulative_percent  
FROM Month_CTE;
 ```

![image](https://user-images.githubusercontent.com/101379141/200459700-f4e5e70a-9c41-4e80-9cc2-29a58fe8d955.png)


**3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?**


```sql
WITH REMOVE_CTE AS (    SELECT  interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) < 6)
SELECT COUNT(*) AS data_remove
FROM interest_metrics i 
RIGHT JOIN REMOVE_CTE r ON i.interest_id = r.interest_id;

```

![image](https://user-images.githubusercontent.com/101379141/200460015-0a5d4300-d6c3-4d1d-a3f5-70c2c296f4c7.png)


**4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.**


```sql
WITH REMOVE_CTE AS (    SELECT  interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) < 6
                        ),

REMOVE_Month_CTE AS (   SELECT month_year, count(*) as total_remove
                        FROM interest_metrics i 
                        RIGHT JOIN REMOVE_CTE r ON i.interest_id = r.interest_id
                        GROUP BY month_year
                        ),

ORIGINAL_CTE AS (       SELECT month_year, count(*) as total_original
                        FROM interest_metrics i 
                        WHERE month_year is not null 
                        GROUP BY month_year 
                )

SELECT O.month_year,
        total_original,
        total_remove,
        format( cast(total_remove as float) / total_original,'p') as remove_percent
FROM ORIGINAL_CTE O
JOIN REMOVE_Month_CTE R on O.month_year = R.month_year
ORDER BY O.month_year;
```

![image](https://user-images.githubusercontent.com/101379141/200460143-4d731cbe-af40-4312-9dd1-1c5d58034478.png)

- Overall, We can see that the percent of removed month_year which have cumulative percent lower than 90% , is very low and not significant. So removing these values can increase performance by attracting customer to interest one. So it's okie to remove these one. 


**5. After removing these interests - how many unique interests are there for each month?**


```sql
WITH INTEREST_CTE AS    (SELECT interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) >= 6
                        )

SELECT month_year,
        COUNT(*) AS interest_month_cnt
FROM interest_metrics i1
RIGHT JOIN  INTEREST_CTE i2 ON I1.interest_id = I2.interest_id
WHERE month_year IS NOT NULL
GROUP BY month_year
ORDER BY month_year;
```
![image](https://user-images.githubusercontent.com/101379141/200460404-0ac74dcc-06ce-4cd4-83c0-f6096c182ab4.png)

---
# C. Segment Analysis

**1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`**

- Let's create the filtered (sub_metrics) table first

```sql

DROP TABLE IF EXISTS sub_metrics;

WITH REMOVE_CTE AS    (SELECT interest_id , 
                                COUNT(DISTINCT month_year) as total_months
                        FROM interest_metrics i1
                        WHERE month_year IS NOT NULL
                        GROUP BY interest_id
                        HAVING COUNT(DISTINCT month_year) < 6
                        )
SELECT i.*
INTO sub_metrics 
FROM interest_metrics i
WHERE I.interest_id NOT IN (SELECT interest_id FROM REMOVE_CTE )

```

- Top 10 which have the largest composition values in any month_year ?

```sql
SELECT top 10 month_year, interest_name, composition
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
ORDER BY composition DESC ;
```

Result:

![image](https://user-images.githubusercontent.com/101379141/200461616-8bfaa39f-40fe-436f-91f8-526ee8240cc0.png)

- Bottom 10 interests which have the largest composition values in any month_year?


```sql
SELECT top 10 month_year, interest_name, composition
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
ORDER BY composition ;
```

Result:

![image](https://user-images.githubusercontent.com/101379141/200461758-4a7f96a7-dcd5-46dc-944e-3019e00c965f.png)


**2. Which 5 interests had the lowest average ranking value?**


```sql
SELECT top 5 interest_name, AVG(ranking) AS AVERAGE_RANK 
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
GROUP BY interest_name
ORDER BY AVERAGE_RANK DESC  ;
```

Output:
![image](https://user-images.githubusercontent.com/101379141/200461891-45a641cf-931f-489e-b5d4-9cf0219ce2bd.png)

**3. Which 5 interests had the largest standard deviation in their `percentile_ranking` value?**


```sql
SELECT  top 5 interest_name, 
        ROUND(STDEV(percentile_ranking),2) AS STD_DEV_ranking 
FROM sub_metrics s
LEFT JOIN interest_map  i ON S.interest_id = I.id
WHERE month_year is not null 
GROUP BY interest_name
ORDER BY STD_DEV_ranking DESC    ;
```

Output:
![image](https://user-images.githubusercontent.com/101379141/200462094-ca95ead6-2264-46c7-98e7-0aba5082d778.png)


**4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?**

- Because these 5 interest_name has the highest standard deviation so, the gap between max and min of their percentile_ranking is really large, and decrease dramatically by time . For example : percentile ranking of Techies peeked at 86.69 , but it fell to the lowest point with 7.92.

```sql
WITH TOP_5_CTE AS (     SELECT  TOP 5 interest_name, 
                                ROUND(STDEV(percentile_ranking),2) AS STD_DEV_ranking 
                        FROM sub_metrics s
                        LEFT JOIN interest_map  i ON S.interest_id = I.id
                        WHERE month_year is not null 
                        GROUP BY interest_name
                        ORDER BY STD_DEV_ranking DESC  ),

MIN_MAX_CTE AS (SELECT  month_year, 
                        interest_name,
                        percentile_ranking,
                        MAX(percentile_ranking) OVER(PARTITION BY interest_name   ) AS MAX_VALUE,
                        MIN(percentile_ranking) OVER(PARTITION BY interest_name  ) AS MIN_VALUE
                FROM sub_metrics s
                LEFT JOIN interest_map  i ON S.interest_id = I.id
                WHERE interest_name in (SELECT interest_name FROM TOP_5_CTE) 
                )

SELECT  month_year, 
        interest_name,
        percentile_ranking
FROM MIN_MAX_CTE 
WHERE  percentile_ranking = MAX_VALUE OR percentile_ranking  = MIN_VALUE      
ORDER BY interest_name,percentile_ranking DESC ;
```

Output:

![image](https://user-images.githubusercontent.com/101379141/200462361-544b97f5-75a5-4a33-921d-b813774a51db.png)


**5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?**

- In overall, I can make a conclusion that the customer have a high interest in traveling and buying luxury furniture  in interms of composition value and ranking. So increasing the the presence of advertising about these top interest topics is valuable step for increasing of performance.
- By the way, excluding the topics like Astrology or Video Games or limit their presence would bring positive performance for company. 

---
# D. Index Analysis

The `index_value` is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the `composition` column by the `index_value` column rounded to 2 decimal places.

**1. What is the top 10 interests by the average composition for each month?**


```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE)

SELECT *
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10;
```

Example output for **2018-07-01**:

![image](https://user-images.githubusercontent.com/101379141/200462840-8cf60272-aff2-4989-9b48-503738e84c74.png)


**2. For all of these top 10 interests - which interest appears the most often?**



```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE)

SELECT interest_name, COUNT(*) AS Count_Appearance
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10
GROUP BY interest_name
ORDER BY Count_Appearance DESC ;
```

Output: First 10 results

![image](https://user-images.githubusercontent.com/101379141/200462975-67b8a700-2a46-4456-9ff8-909afa159099.png)


**3. What is the average of the average composition for the top 10 interests for each month?**


```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE)

SELECT month_year, AVG(average_composition) AS AVERAGE_AVG_COMP
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10
GROUP BY month_year
ORDER BY month_year;
```

Output:

![image](https://user-images.githubusercontent.com/101379141/200463420-2e50685b-419e-4842-a92b-608365afccb5.png)



**4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.**

Required output for question 4:

    <details>
    <summary>Click to expand</summary>

    | month_year | interest_name                 | max_index_composition | 3_month_moving_avg | 1_month_ago                       | 2_months_ago                      |
    | :--------- | :---------------------------- | :-------------------- | :----------------- | :-------------------------------- | :-------------------------------- |
    | 2018-09-01 | Work Comes First Travelers    | 8.26                  | 7.61               | Las Vegas Trip Planners: 7.21     | Las Vegas Trip Planners: 7.36     |
    | 2018-10-01 | Work Comes First Travelers    | 9.14                  | 8.20               | Work Comes First Travelers: 8.26  | Las Vegas Trip Planners: 7.21     |
    | 2018-11-01 | Work Comes First Travelers    | 8.28                  | 8.56               | Work Comes First Travelers: 9.14  | Work Comes First Travelers: 8.26  |
    | 2018-12-01 | Work Comes First Travelers    | 8.31                  | 8.58               | Work Comes First Travelers: 8.28  | Work Comes First Travelers: 9.14  |
    | 2019-01-01 | Work Comes First Travelers    | 7.66                  | 8.08               | Work Comes First Travelers: 8.31  | Work Comes First Travelers: 8.28  |
    | 2019-02-01 | Work Comes First Travelers    | 7.66                  | 7.88               | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 8.31  |
    | 2019-03-01 | Alabama Trip Planners         | 6.54                  | 7.29               | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 7.66  |
    | 2019-04-01 | Solar Energy Researchers      | 6.28                  | 6.83               | Alabama Trip Planners: 6.54       | Work Comes First Travelers: 7.66  |
    | 2019-05-01 | Readers of Honduran Content   | 4.41                  | 5.74               | Solar Energy Researchers: 6.28    | Alabama Trip Planners: 6.54       |
    | 2019-06-01 | Las Vegas Trip Planners       | 2.77                  | 4.49               | Readers of Honduran Content: 4.41 | Solar Energy Researchers: 6.28    |
    | 2019-07-01 | Las Vegas Trip Planners       | 2.82                  | 3.33               | Las Vegas Trip Planners: 2.77     | Readers of Honduran Content: 4.41 |
    | 2019-08-01 | Cosmetics and Beauty Shoppers | 2.73                  | 2.77               | Las Vegas Trip Planners: 2.82     | Las Vegas Trip Planners: 2.77     |

    </details>

    Query:

```sql
WITH CTE AS (   SELECT  month_year, 
                        interest_name,
                        CAST( composition/index_value AS FLOAT) as average_composition
                FROM interest_metrics i
                LEFT JOIN interest_map i2 ON i.interest_id = i2.id
                WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (SELECT     month_year, 
                        Interest_name,
                        average_composition,
                        rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
                FROM CTE),

MAX_CTE AS  (   SELECT  month_year,
                        interest_name,
                        ROUND(AVG(average_composition),2) AS AVERAGE_AVG_COMP
                FROM RANK_CTE
                WHERE RANK_Avg_Comp = 1
                GROUP BY month_year,interest_name
                ),

AVG_3month_CTE AS (SELECT *,
                        ROUND(AVG(AVERAGE_AVG_COMP) OVER (ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  ),2) AS '3_month_moving_avg'
                FROM MAX_CTE),


LAG_CTE as (SELECT *,
                        ROUND(LAG(AVERAGE_AVG_COMP,1) OVER(ORDER BY month_year),2) AS '1_month',
                        ROUND(LAG(AVERAGE_AVG_COMP,2) OVER(ORDER BY month_year),2) AS '2_month',
                        CONCAT( LAG(interest_name,1) OVER(ORDER BY month_year)  , ':',LAG(AVERAGE_AVG_COMP,1) OVER(ORDER BY month_year)) AS '1_month_ago'	,
                        CONCAT( LAG(interest_name,2) OVER(ORDER BY month_year)  , ':',LAG(AVERAGE_AVG_COMP,2) OVER(ORDER BY month_year)) AS '2_month_ago'
                        FROM AVG_3month_CTE )
                
SELECT month_year,
        interest_name,
        AVERAGE_AVG_COMP,
        [1_month_ago],
        [2_month_ago]
FROM LAG_CTE
WHERE [1_month] IS NOT NULL AND [2_month] IS NOT NULL;
```
Output:

![image](https://user-images.githubusercontent.com/101379141/200463318-844f9c39-6412-4ecf-acb2-19df05b76d86.png)   |


**5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?**

- One reason for the fluctuation of Max Average Composition is demanding of customer changing by season. You can see that, The topics relavant to traveling is hot one due to hot season of traveling (end of year or summer)
