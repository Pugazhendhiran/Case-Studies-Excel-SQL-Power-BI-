

--Q1. Number of orders by month based on order status (Delivered vs. canceled vs. etc.) - Split of order status by month

select datename(month, ORDER_DATE) month,ORDER_STATUS, count(order_number) no_of_orders
from orders group by datename(month, ORDER_DATE),ORDER_STATUS
order by month, no_of_orders desc

--Q2. Number of orders by month based on delivery status

select datename(month, ORDER_DATE) month,DELIVERY_STATUS, count(order_number) count_of_orders
from orders group by datename(month, ORDER_DATE),DELIVERY_STATUS
order by month, DELIVERY_STATUS

--Q3. Month-on-month growth in OrderCount and Revenue (from Nov�15 to July�16)
WITH MonthlyData AS (
    SELECT 
        YEAR(ORDER_DATE) AS OrderYear,
        month(ORDER_DATE) AS OrderMonth,
        count(ORDER_NUMBER) AS TotalOrderCount,
        SUM(ORDER_TOTAL-DISCOUNT) AS TotalRevenue
    FROM Orders  
    GROUP BY 
        YEAR(ORDER_DATE),
        month(ORDER_DATE)
)
SELECT 
    CONCAT(OrderYear,'-', OrderMonth) AS Month, TotalOrderCount,TotalRevenue,
    LAG(TotalOrderCount) OVER (ORDER BY OrderYear, OrderMonth) AS PreviousOrderCount,
    LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth) AS PreviousRevenue,
    CASE 
        WHEN LAG(TotalOrderCount) OVER (ORDER BY OrderYear, OrderMonth) IS NULL THEN NULL
        ELSE (TotalOrderCount - LAG(TotalOrderCount) OVER (ORDER BY OrderYear, OrderMonth)*1.0) / NULLIF(LAG(TotalOrderCount) OVER (ORDER BY OrderYear, OrderMonth), 0) * 100 
    END AS OrderCountGrowth,
    CASE 
        WHEN LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth) IS NULL THEN NULL
        ELSE (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth)) / NULLIF(LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth), 0) * 100 
    END AS RevenueGrowth
FROM MonthlyData


--Q4. Month-wise split of total order value of the top 50 customers (The top 50 customers need to identified based on their total order value)
with top_cust as 
(select top 50 CUSTOMER_KEY, sum(order_total) as tot_order_val from orders
group by CUSTOMER_KEY
order by sum(order_total) desc)
select month(order_date) month, sum(order_total) as order_total
from orders where customer_key in (select customer_key from top_cust)
group by month(order_date)

--Q5. Month-wise split of new and repeat customers. New customers mean, new unique customer additions in any given month
with CustomerSummary as
    (select year(ORDER_DATE) AS OrderYear, month(ORDER_DATE) AS OrderMonth, CUSTOMER_KEY, count(*) AS OrderCount,
        row_number() over (partition by CUSTOMER_KEY order by year(ORDER_DATE), month(ORDER_DATE)) AS CustomerOrderCount
    from orders
group by year(ORDER_DATE),month(ORDER_DATE),CUSTOMER_KEY)
select OrderYear, OrderMonth, sum(case when CustomerOrderCount = 1 then 1 else 0 end) as NewCustomers,
    sum(case when CustomerOrderCount > 1 then 1 else 0 end) as RepeatCustomers from CustomerSummary
group by OrderYear, OrderMonth
order by OrderYear, OrderMonth;

--  Q6. 
/*Write stored procedure code which take inputs as location & month, and the output is total_order value and 
number of orders by Gender, Delivered Status for given location & month. Test the code with different options*/

create procedure  Stored_proc 
@location nvarchar(20), @month nvarchar(10)
as
select gender, delivery_status,sum(order_total) total_order  from Orders o inner join customer c
on o.CUSTOMER_KEY=c.CUSTOMER_KEY
where Location=@location and month(o.ORDER_DATE)=@month
group by Gender, DELIVERY_STATUS
go
exec Stored_proc @location='Bangalore', @month='6'
exec Stored_proc @location='Chennai', @month='2'

--#7-- Create Customer 360 File with Below Columns using Orders Data & Customer Data 
    
	CREATE VIEW Customer_360 AS
SELECT 
    c.Customer_ID,
    c.CONTACT_NUMBER,
    c.Referred_Other_Customers,
    c.Gender,
    c.Location,
    c.Acquired_Channel,
    COUNT(o.[ORDER_NUMBER]) AS No_of_Orders,
    SUM(o.ORDER_TOTAL) AS Total_Order_Value,
    SUM(CASE WHEN o.Discount > 0 THEN 1 ELSE 0 END) AS Total_Orders_with_Discount,
    SUM(CASE WHEN o.Delivery_Status = 'Late' THEN 1 ELSE 0 END) AS Total_Orders_Received_Late,
    SUM(CASE WHEN o.ORDER_TOTAL <=0 THEN 1 ELSE 0 END) AS Total_Orders_Returned,
    MAX(o.ORDER_TOTAL) AS Maximum_Order_Value,
    MIN(o.Order_Date) AS First_Transaction_Date,
    MAX(o.Order_Date) AS Last_Transaction_Date,
    DATEDIFF(MONTH, MIN(o.Order_Date), MAX(o.Order_Date)) AS Tenure_Months,
    SUM(CASE WHEN o.ORDER_TOTAL = 0 THEN 1 ELSE 0 END) AS No_of_Orders_with_Zero_Value FROM Customer c
LEFT JOIN Orders o ON c.CUSTOMER_KEY = o.CUSTOMER_KEY
GROUP BY c.Customer_ID, c.CONTACT_NUMBER, c.Referred_Other_Customers, c.Gender, c.[Location], c.Acquired_Channel;





--Q8. Total Revenue, total orders by each location

select location,round(sum(order_total-discount),2) as total_revenue, count(order_number) as count_of_orders
from customer c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
group by Location

--Q9. Total revenue, total orders by customer gender
select Gender,round(sum(order_total-discount),2) total_revenue, count(order_number) count_of_orders
from customer c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
group by Gender

--Q10. Which location of customers cancelling orders maximum?
select location, count(order_number) as count_of_orders
from customer c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
where ORDER_STATUS = 'Cancelled'
group by Location
order by count_of_orders desc
offset 0 rows
fetch next 1 row only

--Q11. Total customers, Revenue, Orders by each Acquisition channel
select Acquired_Channel,count(c.CUSTOMER_KEY) total_customers,sum(order_total-discount) total_revenue, count(order_number) as count_of_orders
from customer c inner join orders o
on c.CUSTOMER_KEY = o.CUSTOMER_KEY
group by Acquired_Channel

--Q12. Which acquisition channel is good interms of revenue generation, maximum orders, repeat purchasers?

select  Acquired_Channel,SUM(ORDER_TOTAL-DISCOUNT) TotalRevenue, count(order_number) Order_counts from Orders o inner join customer c 
on o.CUSTOMER_KEY=c.CUSTOMER_KEY
group by Acquired_Channel
order by TotalRevenue desc, Order_counts desc

--Q13. Write User Defined Function (stored procedure) which can take input table which create two tables with numerical variables and categorical variables separately (6 Marks)

CREATE PROCEDURE SeparateVariables
    @InputTableName NVARCHAR(255),
    @NumericalTableName NVARCHAR(255),
    @CategoricalTableName NVARCHAR(255)
AS
BEGIN
    EXEC('CREATE TABLE ' + @NumericalTableName + ' (variable_name NVARCHAR(255))');

    EXEC('CREATE TABLE ' + @CategoricalTableName + ' (variable_name NVARCHAR(255))');

    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        DECLARE @ColumnName NVARCHAR(255),
                @DataType NVARCHAR(50);

        DECLARE col_cursor CURSOR FOR
            SELECT COLUMN_NAME, DATA_TYPE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = ''' + @InputTableName + ''';

        OPEN col_cursor;

        FETCH NEXT FROM col_cursor INTO @ColumnName, @DataType;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @DataType IN (''int'', ''bigint'', ''decimal'', ''float'', ''real'', ''numeric'')
            BEGIN
                INSERT INTO ' + @NumericalTableName + ' (variable_name) VALUES (@ColumnName);
            END
            ELSE
            BEGIN
                INSERT INTO ' + @CategoricalTableName + ' (variable_name) VALUES (@ColumnName);
            END

            FETCH NEXT FROM col_cursor INTO @ColumnName, @DataType;
        END;

        CLOSE col_cursor;
        DEALLOCATE col_cursor;
    ';

    EXEC sp_executesql @SQL;
END;

EXEC SeparateVariables 'InputTableName', 'NumericalTableName', 'CategoricalTableName';

--Q14
--1   Which month has the most cancellations
select top 1 datename(month,(order_date)), count(order_status) count_of_Cancellations from Orders o inner join customer c 
on o.CUSTOMER_KEY=c.CUSTOMER_KEY
where order_status='Cancelled'
group by datename(month,(order_date))
order by count_of_Cancellations desc

--2  Gender wise preferences of channel

select gender, Acquired_Channel, count(Acquired_Channel) counts_of_preferences from customer
group by gender, Acquired_Channel

--3 Which month has the most late delivery status

select datename(month,(order_date)), count(order_status) count_of_Late_deliveries from Orders o inner join customer c 
on o.CUSTOMER_KEY=c.CUSTOMER_KEY
where DELIVERY_STATUS='LATE'
group by datename(month,(order_date))
order by count_of_Late_deliveries desc
offset 0 rows
fetch next 1 row only

--4 Which channel has the poor delivery status

select top 1 Acquired_Channel,count(delivery_status) late_counts from Orders o inner join customer c 
on o.CUSTOMER_KEY=c.CUSTOMER_KEY
where DELIVERY_STATUS='LATE'
group by Acquired_Channel
order by late_counts

--5 year wise total_orders

select year(order_date) year, count(order_number) order_counts from Orders
group by year(ORDER_DATE)



