#1. What is the total amount each customer spent at the restaurant?

select distinct customer_id, sum(menu.price) as total_amount
from sales
inner join menu on sales.product_id=menu.product_id
group by 1;


#2. How many days has each customer visited the restaurant?

select customer_id, count(*)as no_of_days
from sales 
group by 1


#3. What was the first item from the menu purchased by each customer?

with raw as 
(
  select 
     sales.customer_id, 
     menu.product_name, 
     sales.order_date,
     dense_rank() OVER (PARTITION BY sales.customer_id 
                        ORDER BY sales.order_date DESC) item_rank
 from sales
 join menu on sales.product_id=menu.product_id
)
select customer_id,product_name
from raw
where item_rank = 1
group by 1,2



#4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name, count(*) as purchased_times
from sales s
join menu m on s.product_id=m.product_id
group by 1 
order by 1 desc
limit 1


#5. Which item was the most popular for each customer?

with raw as
(
 select s.customer_id, m.product_name, count(*) as amount
 from sales s
 join menu m on s.product_id=m.product_id
 group by 1,2 
),
raw2 as 
(
 select *, dense_rank() over (partition by customer_id order by amount desc ) as ranks
    from raw
    group by 1,2
)
select customer_id,product_name, amount
from raw2
where ranks = 1
group by 1,2


#6. Which item was purchased first by the customer after they became a member?

select s.customer_id, menu.product_name, min(s.order_date) as date_order, date(m.join_date) as join_date
from sales s
join members m on s.customer_id=m.customer_id
join menu on s.product_id=menu.product_id
where s.order_date>= m.join_date
group by 1


#7. Which item was purchased just before the customer became a member?

select s.customer_id, menu.product_name, s.order_date, date(m.join_date) as join_date
from sales s
join members m on s.customer_id=m.customer_id
join menu on s.product_id=menu.product_id
where s.order_date< m.join_date
group by 1,2


#8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id) as total_items, sum(menu.price) as amount_spent
 from sales s
 join members m on s.customer_id=m.customer_id
 join menu on s.product_id=menu.product_id
 where s.order_date< m.join_date
 group by 1
 
 
 
 #9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
 
 with point as 
(
 select *, 
  case
   when lower(product_name)='sushi' then price*20
            else price*10
  end as product_point
 from menu
)
select s.customer_id,sum( p.product_point) as total_point
from sales s
join point p on s.product_id=p.product_id
group by 1 ;


#10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customers A and B have at the end of January

with dates_cte as
(
 select *, 
  DATE_ADD(join_date, interval 6 day) as valid_date, 
  last_day('2021-01-01') as last_date
 from members as m
)
select d.customer_id, m.product_name, 
 sum(case
  when m.product_name = 'sushi' then 2 * 10 * m.price
  when s.order_date between d.join_date and d.valid_date then 2 * 10 * m.price
  else 10 * m.price
  end) as points
from dates_cte as d
join sales as s on d.customer_id = s.customer_id
join menu as m ON s.product_id = m.product_id
where s.order_date < d.last_date
group by 1,2
