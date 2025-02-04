USE FAASOS_FOOD_ANALYSIS

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


--Driver and Customer Experience


--1. What was the average time in minutes it took for each driver to arrive at the fassos HQ to pick up the order?

 select driver_id, sum(diff)/ count(order_id) 
 from(
     select * 
	 from
         (select *, row_number() over(partition by order_id order by diff) ranks 
	 from
         (select c.order_id,c.customer_id,c.roll_id, c.not_include_items, c.extra_items_included, c.order_date, 
                 d.driver_id, d.pickup_time, d.distance,d.duration, d.cancellation,
				 DATEDIFF(minute,c.order_date,d.pickup_time) diff
 from Customer_Orders c
 inner join Driver_Order d on c.order_id= d.order_id
 where d.pickup_time is not null)a )b where ranks= '1')c
 group by driver_id



--  2. is there any relationship between the number of rolls and how long the order takes to prepare ?

  select order_id, sum( roll_id) count_of_rolls, sum(diff)/count(roll_id) tym
  from
       (select c.order_id,c.customer_id,c.roll_id, c.not_include_items,
	   c.extra_items_included, c.order_date, d.driver_id, d.pickup_time, 
	   d.distance,d.duration, d.cancellation, DATEDIFF(minute,c.order_date,d.pickup_time) diff
 from Customer_Orders c
 inner join Driver_Order d 
 on c.order_id= d.order_id
 where d.pickup_time is not null)a 
 group by order_id


  --3. what was the average distance travelled for each customer?

  select customer_id, sum(distance)/ count(order_id) avg_dist 
  from(
        select * 
		from
            (select *, row_number() over(partition by order_id order by diff) ranks 
	    from
            (select c.order_id,c.customer_id,c.roll_id, 
			   c.not_include_items, c.extra_items_included, c.order_date, d.driver_id,
			   d.pickup_time, cast(trim(replace(d.distance,'km',''))as decimal(4,2))as distance,
			   d.duration, d.cancellation, DATEDIFF(minute,c.order_date,d.pickup_time) diff 
 from Customer_Orders c
 inner join Driver_Order d on c.order_id= d.order_id
 where d.pickup_time is not null)a)b where ranks='1')c
 group by customer_id



  --4.what was the difference between the longest and shortest delivery times for all orders?


select max(duration)- min(duration) diff 
from(
     select cast(case when duration like '%min%' 
	                  then left (duration ,charindex('m', duration)-1)
					  else duration end as integer) as duration 
from driver_order where duration is not null)a