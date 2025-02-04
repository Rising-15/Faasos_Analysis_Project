USE FAASOS_FOOD_ANALYSIS

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

--ROLLS METRICS

--1. How many rolls were ordered?
Select count (roll_id) from customer_orders

--2. How many unique customer orders were made?
Select count(distinct customer_id) AS Unique_customer from customer_orders
 

--3. How many successful orders were delivered by each driver?

SELECT driver_id, COUNT(order_id) AS successful_delivered_orders
FROM driver_order
WHERE cancellation not in ('cancellation','customer cancellation') or cancellation is null
GROUP BY driver_id


--4. How many of each type of roll was delivered?

select c.roll_id, r.roll_name, count(c.roll_id) as delivered_rolls  
from customer_orders c 
join rolls r 
on c.roll_id = r.roll_id 
where order_id in
 (select order_id from driver_order
    WHERE cancellation not in ('cancellation','customer cancellation') or cancellation is null)
group by c.roll_id, r.roll_name

--5. How many veg and non veg rolls were ordered by each customer? 

select c.customer_id, c.roll_id, r.roll_name, count(c.roll_id) as ordered_rolls 
from customer_orders c 
join rolls r
on c.roll_id= r.roll_id
group by c.customer_id, c.roll_id, r.roll_name
order by roll_id


--6. what was the maximum number of rolls delivered in a single order?

select top 1 order_id, count(roll_id) as Max_rolls 
from customer_orders 
where order_id in
    (select order_id from driver_order
         WHERE cancellation not in ('cancellation','customer cancellation') or cancellation is null)
group by order_id
order by Max_rolls desc


--7. For each customer, how many delivered rolls had at least 1 change and how many had no change?

-- with subquery

select customer_id, Instruction, count(Instruction) 
from(
select customer_id , 
             (case when New_not_include_items ='0' and New_extra_items_included = '0'
			       then 'No_chg' else 'chg' end) as Instruction 
from(
   select order_id, customer_id , case when not_include_items is null or not_include_items= ''
                                       or not_include_items = 'Nan' or not_include_items = 'null '
			                           then '0' else '1' end as New_not_include_items,
                                  case when extra_items_included is null or extra_items_included = ''
                                       or extra_items_included = 'Nan' or extra_items_included = 'null '
		                               then '0' else '1' end as New_extra_items_included
from customer_orders
where order_id in
          (select order_id from driver_order
             WHERE cancellation not in ('cancellation','customer cancellation') or cancellation is null))x)y
group by customer_id, Instruction


-- with clause

with temp_Customer_Orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id, customer_id, roll_id, 
                   case when not_include_items is null or not_include_items= '  ' 
                        or not_include_items= 'null' 
						then '0' else not_include_items end as new_not_include_items,
                    case when extra_items_included is null or extra_items_included= '  '  
					     or extra_items_included= 'Nan' or extra_items_included= 'null' 
                        then  '0' else extra_items_included end as new_extra_items_included, order_date
from customer_orders
) 
,
 temp_driver_order(order_id ,driver_id,pickup_time,distance,duration,new_cancellation) as 
(
select order_id, driver_id, pickup_time, distance, duration,
        case when cancellation in ('cancellation', 'customer cancellation') 
		then 0 else 1 end as new_cancellation from Driver_Order
)

select  customer_id,count(order_id),chg_no_chg 
from(
      select *,case when not_include_items = '0' and extra_items_included= '0'
	           then 'nochange' else 'change' end as chg_no_chg
from temp_Customer_Orders 
where order_id in(
               select order_id from temp_driver_order where new_cancellation != 0))a
group by customer_id, chg_no_chg
 
--8. how many rolls were deleivered that had both exclusion and extras?

with temp_customer_order( order_id, customer_id, roll_id, not_include_items, extra_items_included, order_date) as

( select order_id, customer_id, roll_id, case when not_include_items is null or not_include_items = ' ' 
                                              or not_include_items= ' NaN ' or not_include_items= 'null' 
										      then '0' else not_include_items end as new_not_items_included,
                                         case when extra_items_included is null or not_include_items = ' '
										      or extra_items_included = 'NaN' or extra_items_included= 'null'
											  then '0' else extra_items_included end as new_extra_items_included, 
order_date from Customer_Orders
)
,
  temp_driver_order (order_id, driver_id, pickup_time, distance, duration, cancellation) as

( select order_id, driver_id, pickup_time, distance, duration, 
                             case when cancellation is null or cancellation= 'Nan' or cancellation='Null'
							 then 'delivered'else 'Not_Delivered' end 
from Driver_Order)

  select count(actual_status) as Number_of_changes, actual_status 
  from(
        select *,case when not_include_items !='0' and extra_items_included !='0'  
		              then 'both inc and excl' else 'either 1 inc or excl' end
                      as actual_status  
  from temp_customer_order 
  where order_id in(
              select order_id from temp_driver_order where cancellation = 'delivered'))a
  group by actual_status


--9. what was the total number of rolls ordered for each hour of the day? 


select each_hour_info, count( each_hour_info)number_of_orders_per_hr
from( 
     select *, concat (datename(hour,order_date), '-',datename(hour,order_date)+ 1) as each_hour_info 
	 from customer_orders)a 
group by each_hour_info



--10. what was the number of orders for each day of the week?

 select DOW,count(DOW) number_of_orders
 from(
      select*, datename( WEEKDAY,order_date) DOW 
	  from customer_orders)a 
 group by DOW

