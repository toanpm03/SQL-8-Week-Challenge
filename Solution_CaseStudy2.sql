--DATA PREPROCESSING
--Create temp table customer_orders
DROP TABLE IF EXISTS #customer_orders, #customer_orders_split;
	select order_id, customer_id, pizza_id,
			case
				when exclusions = 'null' or exclusions IS NULL then ''
				when exclusions =' ' then ''
				else exclusions
			end as exclusions,
			case 
				when extras ='null' then ''
				when (extras is null) then ''
				when extras ='' then ''
				else extras 
			end as  extras, LEFT(order_time, CHARINDEX(' ', order_time + ' ') - 1) as days,
        right(order_time, CHARINDEX(' ', order_time + ' ')-3) as time
	into #customer_orders --temptable using insert into
	from customer_orders;

-- split row in exclusions and extras columns
DROP TABLE IF EXISTS  #customer_orders_split;
WITH customer_orders_CTE (order_id, customer_id, pizza_id, exclusions, extras, days,time)  
AS  
(
    SELECT 
		order_id, customer_id, pizza_id, 
		trim(value)exclusions,trim(value)extras, days,time
    FROM #customer_orders 
    CROSS APPLY STRING_SPLIT(exclusions, ',')  
)  
SELECT 
	order_id, customer_id, pizza_id, 
	exclusions,extras, days,time
into #customer_orders_split
FROM customer_orders_CTE
CROSS APPLY STRING_SPLIT(extras, ',')
order by order_id, customer_id, pizza_id, exclusions, extras;
alter table #customer_orders_split
	alter column exclusions int;
alter table #customer_orders_split
	alter column extras int;

	--------------------------------------------------------
--temp table runner_orders
select * from runner_orders
drop table  if exists #runner_orders;
	select order_id, runner_id, 
			cast( case
				when pickup_time = 'null' or pickup_time IS NULL then ''
			
				else pickup_time
				end as datetime) pickup_time,
			cast(case
				when distance = 'null' or distance IS NULL then '' 
				when distance like '%km' then trim('km' from distance)
				else distance end as float) distance,
			CAST(case 
					when duration is null or duration = 'null' then ''
					when duration like '%mins' then trim('mins' from duration)
					when duration like '%minute' then trim('minute' from duration)
					when duration like '%minutes' then trim('minutes' from duration)
					else duration end as int) duration,
			case
				when cancellation = 'null' or cancellation IS NULL then '' 
				else cancellation
			end as canellation
	into #runner_orders --temporary table
	from runner_orders;
select* from #runner_orders;
---------------
--temp table pizza_recipes to split value 1 column into rows
drop table  if exists #pizza_recipes;
select pizza_id, 
	  trim(value) toppings 
into #pizza_recipes
from 
(
	select pizza_id,
	cast(toppings as varchar)toppings
	from pizza_recipes
)a
CROSS APPLY STRING_SPLIT(toppings, ',') as topping
order by 1;
