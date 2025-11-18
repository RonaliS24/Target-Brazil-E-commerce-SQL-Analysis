--I.Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:
--A.	Data type of all columns in the “customers” table.
select column_name,data_type
from `Target_SQL.INFORMATION_SCHEMA.COLUMNS`
where table_name = 'customers';
--B.	Get the time range between which the orders were placed.
select extract(year from min(order_purchase_timestamp)) as min_date, max(extract(year from order_purchase_timestamp)) as max_date
from `Target_SQL.orders`;
--C.	Count the Cities & States of customers who ordered during the given period.
select count(distinct geolocation_city) as city_count,count(distinct geolocation_state) as state_count
from `Target_SQL.geolocation`;


--II.	In-depth Exploration:
--A.	Is there a growing trend in the no. of orders placed over the past years? 
with cte as(select order_id, extract(year from order_purchase_timestamp) as year,extract(month from order_purchase_timestamp) as month
from `Target_SQL.orders`)
select year,month,count(order_id) as no_of_order
from cte
group by year,month
order by year,month;
--B.	Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
with cte as(select order_id, extract(year from order_purchase_timestamp) as year,extract(month from order_purchase_timestamp) as month
from `Target_SQL.orders`)
select year,month,count(order_id) as no_of_order
from cte
group by year,month
order by year,month;
/*C.	During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)  
•	0-6 hrs : Dawn
•	7-12 hrs : Mornings
•	13-18 hrs : Afternoon
•	19-23 hrs : Night*/
with cte as(select order_id,order_purchase_timestamp, extract(hour from order_purchase_timestamp) as hour_order
from `Target_SQL.orders`)
select 
case 
when hour_order between 0 and 6 then "Dawn"
when hour_order between 7 and 12 then "Morning"
when hour_order between 13 and 18 then "Afternoon"
when hour_order between 19 and 23 then "Night"
end as time,
count(*) as total_orders
from cte
group by time
order by total_orders desc;


--III.	Evolution of E-commerce orders in the Brazil region: 
--A.	Get the month on month no. of orders placed in each state.
select extract(year from o.order_purchase_timestamp) as year_order,extract(month from o.order_purchase_timestamp) as month_order,c.customer_state,count(o.order_id) as no_of_orders
from `Target_SQL.orders` as o 
join `Target_SQL.customers` as c 
on o.customer_id=c.customer_id
group by year_order,month_order,c.customer_state
order by year_order,month_order,c.customer_state;
--B.	How are the customers distributed across all the states?
select count(distinct customer_id) as no_ofcust,customer_state
from `Target_SQL.customers`
group by customer_id,customer_state
order by customer_state,no_ofcust desc;


--IV.	Impact on Economy: Analyse the money movement by e-commerce by looking at order prices, freight and others.
--A.	Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). 
with cte as(select extract(year from o.order_purchase_timestamp) as year,round(sum(p.payment_value),2) as sum
from `Target_SQL.orders` as o 
join `Target_SQL.payments` as p 
on o.order_id=p.order_id
where extract(year from o.order_purchase_timestamp) between 2017 and 2018
and
 extract(month from o.order_purchase_timestamp) between 1 and 8
group by year)
select round((max(sum)-min(sum))/min(sum),2)*100 as percent_inc
from cte;
--B.	Calculate the Total & Average value of order price for each state
select c.customer_state,round(sum(p.payment_value),2) as total_amt,round(avg(p.payment_value),2) as avg_amt
from `Target_SQL.order_info` as o 
join `Target_SQL.payments` as p
on o.order_id=p.order_id
join `Target_SQL.customers` as c
on o.customer_id=c.customer_id
group by c.customer_state
order by total_amt desc,avg_amt ;
--C.	Calculate the Total & Average value of order freight for each state
select c.customer_state,round(sum(o.freight_value),2) as total_amt,round(avg(o.freight_value),2) as avg_amt
from `Target_SQL.order_items` as o 
join `Target_SQL.orders` as od
on o.order_id=od.order_id
join `Target_SQL.customers` as c
on od.customer_id=c.customer_id
group by c.customer_state
order by total_amt desc,avg_amt ;


--V.	Analysis based on sales, freight and delivery time.
/*A.	Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
Do this in a single query.
You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
•	time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
•	diff_estimated_delivery = order_estimated_delivery_date - order_delivered_customer_date*/

select customer_id,order_id,date_diff(order_delivered_customer_date,order_purchase_timestamp,day) as time_to_deliver, date_diff(order_estimated_delivery_date,order_delivered_customer_date,day) as diff_estimated_delivery
from `Target_SQL.orders`;

--B.	Find out the top 5 states with the highest & lowest average freight value.
---highest frieght
select round(avg(oi.freight_value),2) as high_avg_frieght,c.customer_state
from `Target_SQL.order_items` oi
join `Target_SQL.orders` o
on oi.order_id=o.order_id
join `Target_SQL.customers` c 
on o.customer_id=c.customer_id
group by c.customer_state
order by high_avg_frieght desc limit 5;
--lowest frieght
select round(avg(oi.freight_value),2) as low_avg_frieght,c.customer_state
from `Target_SQL.order_items` oi
join `Target_SQL.orders` o
on oi.order_id=o.order_id
join `Target_SQL.customers` c 
on o.customer_id=c.customer_id
group by c.customer_state
order by low_avg_frieght asc limit 5;

--C.	Find out the top 5 states with the highest & lowest average delivery time.
--highest delivery
select ceiling(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day))) as time_to_deliver,c.customer_state
from `Target_SQL.orders` o
join `Target_SQL.customers`c
on o.customer_id=c.customer_id
group by c.customer_state
order by time_to_deliver desc limit 5;
--lowest delivery
select ceiling(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day))) as time_to_deliver,c.customer_state
from `Target_SQL.orders` o
join `Target_SQL.customers`c
on o.customer_id=c.customer_id
group by c.customer_state
order by time_to_deliver asc limit 5;

--D. Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state. 

select round(avg(date_diff(o.order_delivered_customer_date,o.order_estimated_delivery_date,day)),2) as diff_in_delivery,c.customer_state
from `Target_SQL.orders` o
join `Target_SQL.customers` c
on o.customer_id=c.customer_id
group by c.customer_state
order by diff_in_delivery desc limit 5;


--VI.	Analysis based on the payments:
--A.	Find the month on month no. of orders placed using different payment types.
select o.year_order_purchase_timestamp,o.month_order_purchase_timestamp,p.payment_type,count(o.order_id) as no_of_orders
from `Target_SQL.order_info` o
join `Target_SQL.payments` p 
on o.order_id=p.order_id
group by o.year_order_purchase_timestamp,o.month_order_purchase_timestamp,p.payment_type
order by o.year_order_purchase_timestamp,o.month_order_purchase_timestamp,p.payment_type,no_of_orders desc;

--B.	Find the no. of orders placed on the basis of the payment installments that have been paid.

select payment_installments, count(distinct order_id) as no_of_order
from `Target_SQL.payments`
group by payment_installments;