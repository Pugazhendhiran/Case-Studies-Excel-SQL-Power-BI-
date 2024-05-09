create database integrated_case_studies
select * from Orders
select * from customer

--Q1. Total Revenue (order value)

select round(sum(order_total),2) Revenue from orders

--Q2. Total Revenue (order value) by top 25 Customers

select Customer_key, round(sum(order_total),2) as Revenue from orders 
group by Customer_key having sum(order_total) is not null
order by sum(order_total) desc
offset 0 rows
fetch next 25 rows only

--Q3. Total number of orders

select count(*) from Orders

--Q4. Total orders by top 10 customers

select CUSTOMER_KEY, count(customer_key) No_of_orders from orders
group by CUSTOMER_KEY 
order by No_of_orders desc
offset 0 rows
fetch next 10 rows only

--Q6. Number of customers ordered once

select customer_key,count(*)
from Orders group by CUSTOMER_KEY
having count(*)=1




--Q7. Number of customers ordered multiple times

select count(*) Multiple_times
from (select customer_key from Orders
group by CUSTOMER_KEY having count(*)>1) as multiple_times

--Q8. Number of customers reffered to other customers

select count(referred_other_customers) from customer
where referred_other_customers = 'y'

--Q9. Which Month have maximum Revenue?

select month(order_date) month, round(sum(order_total),2) Revenue
from Orders group by month(order_date)
order by Revenue desc
offset 0 rows
fetch next 1 row only

--Q10. Number of customers are inactive (that haven't ordered in the last 60 days)
 
 select count(distinct customer_key) as inactive from Orders
 where ORDER_DATE<=dateadd(day,-60,getdate())

 --Q11. Growth Rate  (%) in Orders (from Nov’15 to July’16)

 select((july_orders)/November_orders)*100 Growth_rate from 
 (select(select count(*) from orders 
 where order_date between '2016-07-01' and '2016-07-31') july_orders,
 (select count(*) from orders where order_date between '2015-11-01' and '2015-11-30') November_orders) Orders

 --Q12. Growth Rate (%) in Revenue (from Nov'15 to July'16)
  select((july_revenue)/November_revenue)*100 Growth_rate from 
 (select(select sum(order_total) from orders 
 where order_date between '2016-07-01' and '2016-07-31') july_revenue,
 (select sum(order_total) from orders where order_date between '2015-11-01' and '2015-11-30') November_revenue) Revenue

 --Q13. What is the percentage of Male customers exists?
    select 
    round((select count(gender) from customer where Gender = 'M') * 100.0/
    (select count(Gender) from customer),2) percentge

--Q14.Which location have maximum customers?

select Location, count(customer_key) as Count_of_customer
from customer
group by Location
order by count(customer_key) desc
offset 0 rows
fetch next 1 row only

--Q15. How many orders are returned? (Returns can be found if the order total value is negative value)

select COUNT(order_number)  Returns from orders
where order_total < 0

--Q16. Which Acquisition channel is more efficient in terms of customer acquisition?

select Acquired_Channel,count(customer_key)  Total_customers from customer
group by Acquired_Channel
order by count(customer_key) desc
offset 0 rows
fetch next 1 row only

--Q17. Which location having more orders with discount amount?

select Location, count(order_number) total_orders, sum(discount) as tot_discount
from customer c inner join orders o
on c.customer_key = o.CUSTOMER_KEY
group by Location
order by count(order_number) desc
offset 0 rows
fetch next 1 row only

--Q18. Which location having maximum orders delivered in delay?

select top 1 Location, count(order_number) total_orders from customer c inner join orders o
on c.customer_key = o.CUSTOMER_KEY
where DELIVERY_STATUS = 'LATE'
group by Location
order by count(order_number) desc;

--Q19. What is the percentage of customers who are males acquired by APP channel?

select 
(SELECT count(CUSTOMER_KEY) no_of_customers from customer
where Gender = 'M' and Acquired_Channel = 'APP') *100.0 /
(select count(gender) total_customers
from customer) percentage

--Q20. What is the percentage of orders got canceled?

select 
(select COUNT(order_number) as no_of_orders from orders
where ORDER_STATUS = 'Cancelled')*100.0 /(select count(order_number) tot_orders from orders) percentage



--Q21. What is the percentage of orders done by happy customers (Note: Happy customers mean customer who referred other customers)?

select
(select count(order_number) as no_of_orders from orders o inner join customer c
on o.CUSTOMER_KEY = c.CUSTOMER_KEY
where Referred_Other_customers = 'Y')*100.0/(select count(order_number) as tot_orders from Orders) 

--Q22. Which Location having maximum customers through reference?

select Location, count(CUSTOMER_KEY) count_of_customers from customer
where Referred_Other_customers = 'Y'
group by Location
order by count_of_customers desc

--Q23. What is order_total value of male customers who are belongs to Chennai and Happy customers (Happy customer definition is same in question 21)?

select sum(order_total) as total_order_value from customer c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
where Referred_Other_customers = 'Y' and Gender = 'M' and Location = 'Chennai'

--Q24. Which month having maximum order value from male customers belongs to Chennai? 

select month(order_date) as month, sum(order_total) as total_order_value from customer as c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
where Gender = 'M' and Location = 'Chennai'
group by month(order_date)
order by total_order_value desc
offset 0 rows
fetch next 1 row only

--Q25. What are number of discounted orders ordered by female customers who were acquired by website from Bangalore delivered on time?

select count(order_number) as count_of_orders_by_Female from customer c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
where location = 'Bangalore' and DELIVERY_STATUS = 'ON-TIME' and gender = 'F' and Acquired_Channel = 'WEBSITE' 

 --Q26_Additonal analysis:
      --1_Total number of Male customers who uses websites 				
	  select count(*) from customer
	  where Acquired_Channel='website' and Gender='M'
	  --2_Which location customers using the App channel most			
      select Location, count(Acquired_channel) from customer
	  where Acquired_Channel='APP'
	  group by Location
	  --3_Which location has the highest late delivery status		
      select location, count(DELIVERY_STATUS) from customer C inner join Orders O
	  on C.CUSTOMER_KEY=O.CUSTOMER_KEY
	  where O.DELIVERY_STATUS='LATE'
	  group by location order by count(DELIVERY_STATUS) desc
	  --4_Count of Genders who have cancelled the orders		
      select Gender, count(ORDER_STATUS) from customer C inner join Orders O
	  on C.CUSTOMER_KEY=O.CUSTOMER_KEY
	  where ORDER_STATUS='Cancelled'
	  group by Gender
	  --5_percentage of On-time delivery status
	  select round(((select  count(delivery_status) percentage from Orders where DELIVERY_STATUS='ON-TIME')*100.0/ (select count(*) from Orders)),2) percentages
	  
      











