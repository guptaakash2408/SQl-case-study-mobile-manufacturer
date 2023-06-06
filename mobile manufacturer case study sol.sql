--SQL Advance Case Study
use mobile_manufacturer
select * from Dim_customer
select * from DIM_DATE
select * from DIM_LOCATION
select * from DIM_MANUFACTURER
select * from DIM_MODEL
select * from FACT_TRANSACTIONS

/*Q1 List all the states in which we have customers who have bought cellphones from 2005 till today */
	select state
	from FACT_TRANSACTIONS as x
	left join DIM_LOCATION as y
	on x.IDLocation = y.IDLocation
	left join DIM_MODEL as z
	on x.IDModel = z.IDModel
	where [date] between '01-01-2005' and GETDATE()


--Q2 What state in the US is buying the most 'Samsung' cell phones?
	select top 1 *
	from
	(
	select Country , State , count(quantity) as qty
	from DIM_LOCATION as x
	left join FACT_TRANSACTIONS as y
	on x.IDLocation = y.IDLocation
	left join DIM_MODEL as z
	on y.IDModel = z.IDModel
	left join DIM_MANUFACTURER as r
	on z.IDManufacturer = r.IDManufacturer
	where Country = 'US'
	group by Country , State
	) as x
	order by qty desc


--Q3 Show the number of transactions for each model per zip code per state.      
	
	SELECT Model_Name,ZipCode,State,count(TotalPrice) as transactions
	FROM DIM_LOCATION AS X
	LEFT JOIN FACT_TRANSACTIONS AS Y
	ON X.IDLOCATION = Y.IDLOCATION
	LEFT JOIN DIM_MODEL as z
	on y.IDModel = z.IDModel
	group by Model_Name,ZipCode,State


--Q4 Show the cheapest cellphone (Output should contain the price also)
select top 1 *
from
(
select IDModel,unit_price,Model_Name
from DIM_MODEL
) as x
order by unit_price


/* Q5 Find out the average price for each model in the top5 manufacturers in terms of sales quantity
      and order by average price.*/
SELECT TOP 5 Manufacturer_Name, avg_price 
FROM (select  Manufacturer_Name , Model_Name ,avg(TotalPrice) as avg_price
from FACT_TRANSACTIONS as x
left join DIM_MODEL as y
on x.IDModel = y.IDModel
left join DIM_MANUFACTURER as z
on y.IDManufacturer = z.IDManufacturer
group by Manufacturer_Name , Model_Name) sub 
order by avg_price desc


--Q6 List the names of the customers and the average amount spent in 2009, where the average is higher than 500

select Customer_Name, [YEAR], AVG(TotalPrice) as avg_amt
from DIM_CUSTOMER as x
left join FACT_TRANSACTIONS as y
on x.IDCustomer = y.IDCustomer
left join DIM_DATE as z
on y.Date = z.DATE
where [YEAR] = 2009
group by Customer_Name, [YEAR]
having avg(TotalPrice) > 500 

--or by cte 
with table1 as (SELECT Customer_Name ,[YEAR], AVG(TotalPrice) as avg_amt
	FROM DIM_CUSTOMER CUST
	JOIN FACT_TRANSACTIONS T
	ON   T.IDCustomer = CUST.IDCustomer
	JOIN DIM_DATE D
	ON   D.Date = T.Date
	where YEAR = '2009'
    GROUP BY Customer_Name,[YEAR]) 

	SELECT * FROM table1 
	where avg_amt>500


	
--Q7 List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010 
WITH TABLE1 AS (SELECT Model_Name ,[YEAR], sum(Quantity) QUANT
FROM DIM_MODEL M
JOIN FACT_TRANSACTIONS T
ON M.IDModel = T.IDModel
JOIN DIM_DATE D
ON D.Date = T.Date
WHERE [YEAR] IN (2008, 2009, 2010)
GROUP BY Model_Name, [YEAR])

SELECT TOP 5 Model_Name, QUANT, [YEAR]
FROM TABLE1
ORDER BY 
    QUANT DESC;

	
/* Q8 Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer 
      with the 2nd top sales in the year of 2010.*/
select top 1 *
from
(
select top 2 IDManufacturer , [year], sum(totalprice*quantity) as totalsales
from DIM_MODEL as x
left join FACT_TRANSACTIONS as y
on x.IDModel = y.IDModel
left join DIM_DATE as z
on y.Date = z.DATE
where [year] = 2009
group by IDManufacturer , [year]
order by totalsales desc
) as x
union

select top 1 *
from
(
select top 2 IDManufacturer , [year], sum(totalprice*quantity) as totalsales
from DIM_MODEL as x
left join FACT_TRANSACTIONS as y
on x.IDModel = y.IDModel
left join DIM_DATE as z
on y.Date = z.DATE
where [year] = 2010
group by IDManufacturer , [year]
order by totalsales desc
) as x
 
 

--Q9 Show the manufacturers that sold cellphones in 2010 but did not in 2009.

SELECT  Manufacturer_Name, MO.IDManufacturer,[YEAR]
FROM DIM_MODEL MO
JOIN FACT_TRANSACTIONS T
ON MO.IDModel = T.IDModel
JOIN DIM_MANUFACTURER MA
ON MO.IdManufacturer = MA.IdManufacturer
JOIN DIM_DATE D
ON D.Date = T.Date
WHERE YEAR = '2010'



EXCEPT

SELECT Manufacturer_Name, MO.IDManufacturer,[YEAR]
FROM DIM_MODEL MO
JOIN FACT_TRANSACTIONS T
ON MO.IDModel = T.IDModel
JOIN DIM_MANUFACTURER MA
ON MO.IdManufacturer = MA.IdManufacturer
JOIN DIM_DATE D
ON D.Date = T.Date
WHERE YEAR = '2009'

;




/* Q10 Find top 100 customers and their average spend, average quantity by each year. 
      Also find the percentage of change in their spend. */
	
WITH TABLE1 AS (SELECT  Customer_Name, 
       [YEAR], 
       AVG(t.TotalPrice) AS avg_spend, 
       AVG(t.Quantity) AS avg_quantity, 
       (AVG(t.TotalPrice) - LAG(AVG(t.TotalPrice)) OVER (PARTITION BY c.IDCustomer ORDER BY [YEAR])) / LAG(AVG(t.TotalPrice)) OVER (PARTITION BY c.IDCustomer ORDER BY [YEAR]) * 100 AS spend_change_percentage
FROM FACT_TRANSACTIONS t
JOIN DIM_CUSTOMER c ON t.IDCustomer = c.IDCustomer
JOIN DIM_DATE d ON t.Date = d.Date
GROUP BY Customer_Name, [YEAR], c.IDCustomer
)

SELECT TOP 10 Customer_Name, 
       [YEAR], avg_spend, avg_quantity, spend_change_percentage  FROM TABLE1 
ORDER BY avg_spend DESC
;
