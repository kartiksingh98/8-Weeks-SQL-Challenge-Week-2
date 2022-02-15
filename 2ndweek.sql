
-- Pizza Metrics
--1

select count(order_id) as total_order from customer_orders

--2
select count( distinct order_id) as unique_otders from customer_orders

--3
select * from runner_orders

select count(*) as completed_orders from runner_orders where cancellation  like ' '
--4
select pizza_id, count(pizza_id) as total_count from customer_orders
group by pizza_id

--5
select a.pizza_id , convert(varchar(20),pizza_name) as pizza_name , count(a.pizza_id) as total_count
from customer_orders a inner join pizza_names b
on a.pizza_id=b.pizza_id
group by a.pizza_id, convert(varchar(20), pizza_name)

--6
select * from customer_orders
select top 1 order_id, count(*) as pizza_count from customer_orders
group by order_id
order by  pizza_count desc

--7
select customer_id,
sum ( case when(( exclusions != ' ' and exclusions !='0')  
or ( extras !=' ' and extras !='0')) then 1
else 0
end) as change,
sum ( case when(( exclusions = ' ' or exclusions ='0')  
and ( extras =' ' or extras ='0')) then 1
else 0
end) as no_change
from customer_orders
group by customer_id

--8
select * from customer_orders
select 
sum ( case when(( exclusions != ' ' and exclusions !='0')  
and ( extras !=' ' and extras !='0')) then 1
else 0
end) as exclusionandextras
from customer_orders

--9
select DATEPART(hour, order_time) as time_of_day, count(*) from customer_orders
group by DATEPART(hour, order_time)

--10
select * from customer_orders

--Runner and Customer Experience
--1
select * from runners
with getweek as(
SELECT runner_id, registration_date, DATEDIFF(WEEKDAY, '2020-12-31', registration_date)/7+1 as week_interval from runners
)
select count(*) as count_name, week_interval from getweek
group by week_interval


--2
select a.runner_id, b.order_id, a.pickup_time, b.order_time,
datediff(minute, order_time, pickup_time) as duration
from runner_orders a inner join customer_orders b
on a.order_id=b.order_id
where distance!='0'
group by a.runner_id, b.order_id, a.pickup_time, b.order_time


--3
with relationship as(
select  b.order_id, count(b.order_id) as pizza_numbers,
datediff(minute, order_time, pickup_time) as duration
from runner_orders a inner join customer_orders b
on a.order_id=b.order_id
where distance!='0'
group by b.order_id, b.order_time, pickup_time
)

select pizza_numbers, avg(duration) from relationship
group by pizza_numbers
select * from runner_orders
select * from customer_orders

--4
select a.customer_id, avg(b.distance)
from customer_orders a join runner_orders b
on a.order_id=b.order_id
where b.duration!='0'
group by a.customer_id

--5
select MAX(duration)- MIN(duration) from runner_orders
where duration!='0'

--6
select runner_id, order_id, distance, duration/60,
(distance/(duration/60)) as speed from runner_orders
where duration!='0'
order by runner_id

--7
with fail_calc as(
select runner_id, sum( 
case when distance !='0' then 1.00
else 0
end
) as success , count(*) as total
from runner_orders
group by runner_id)

select  *, cast(((success)/total)*100 as numeric(5,2)) from fail_calc


--Ingredient Optimzation
--1
with topping_ids as(
select pizza_id, trim(value) as topping_id from pizza_recipes
	cross apply string_split(cast(toppings as varchar(30)),',')
	where rtrim(value)<>' '
	)

select pizza_id, a.topping_id, b.topping_name from topping_ids a
inner join pizza_toppings b on a.topping_id=b.topping_id

--2
with extra_values as(
select trim(value) as extras, count(trim(value)) as value_count
from customer_orders cross apply string_split(cast(extras as varchar(30)), ',')
where extras !=' ' and extras!='0'
group by trim(value)

)

select extras, topping_name, value_count from extra_values a
inner join pizza_toppings  b
on a.extras=b.topping_id
where value_count=(select max(Value_count) from extra_values)

--3
with exclusion_values as(
select trim(value) as exclusion_id, count(trim(value)) as value_count,
DENSE_RANK() over (order by count(trim(value)) desc) as rank
from customer_orders cross apply string_split(cast(exclusions as varchar(30)), ',')
where exclusions !=' ' and exclusions!='0'
group by trim(value))

select a.*, b.topping_name from exclusion_values a
inner join pizza_toppings b on a.exclusion_id=b.topping_id
where rank=1

--Q4 Ambigous question
--Q5 Space for Q5



--Q6 Space for Q6



--Pricing and Ratings

--1
select runner_id,
sum(
case when
pizza_id=1 then 12
else 
10
end) as total
from runner_orders a
inner join customer_orders b
on a.order_id=b.order_id
where a.order_id not in ( select order_id from runner_orders where cancellation != ' ')
group by runner_id

 

 --2
select runner_id,
sum(
case when
pizza_id=1 and ( extras !='0' and extras!=' ') then 12+ len(trim(extras))- LEN(replace(trim(extras),',',''))+1
when pizza_id=1 and (extras='0' or extras=' ')
then 12
when pizza_id=2 and ( extras !='0' and extras!=' ')  then
10+ len(trim(extras))- LEN(replace(trim(extras),',',''))+1
when pizza_id=2 and (extras='0' or extras=' ')
then 10
end) as total
from runner_orders a
inner join customer_orders b
on a.order_id=b.order_id
group by runner_id


--3

create table ratings( runner_id int, order_id int, rating int constraint Check_Runner_Rating check(rating>=0 and rating<=5),
constraint Ratings_PK Primary key(runner_id, order_id))


--4
--space for 4

--5
select  b.runner_id,
sum(
case when
pizza_id=1 then 12- distance*0.30
else
10-distance*0.30
end) as Total_Earning 

from customer_orders a inner join runner_orders b
on a.order_id=b.order_id
where cancellation =' '
group by runner_id