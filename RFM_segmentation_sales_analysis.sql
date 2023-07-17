--Inspecting data
select * from [dbo].[sales_data_sample]
--Checking unique values
select distinct status from [dbo].[sales_data_sample] --Nice one to plot
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] --Nice to plot
select distinct COUNTRY from [dbo].[sales_data_sample] -- Nice to plot
select distinct TERRITORY from [dbo].[sales_data_sample] --Nice to plot
select distinct DEALSIZE from [dbo].[sales_data_sample] -- Nice to plot

select distinct MONTH_ID 
from [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003


--Analysis
--grouping sales by product line
select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc
--grouping sales by YEAR_ID
select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc
--grouping sales by DEALSIZE
select DEALSIZE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc

--what was the best month for sales in a specific year
select MONTH_ID, sum(sales) Revenue, COUNT(QUANTITYORDERED) FREEQUENCY
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 --change the year to see others
group by MONTH_ID
order by 2 desc

--Novermber seems to be the best month, lets see what products are sold in novermber
select MONTH_ID, PRODUCTLINE, sum(sales) Revenue, COUNT(QUANTITYORDERED) FREEQUENCY
from [dbo].[sales_data_sample]
where MONTH_ID = 11 and YEAR_ID = 2004 --change the year to see others
group by PRODUCTLINE, MONTH_ID
order by 3 desc

--who is our best customer (this will be answered using RFM)

;With rfm as
	(SELECT
	CUSTOMERNAME,
	sum(SALES) MONETARYVALUE,
	avg(SALES) AVGMONETARYVALUE,
	COUNT(QUANTITYORDERED) FREEQUENCY,
	max(ORDERDATE) LastOrderDate,
	(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
	DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	FROM [dbo].[sales_data_sample]
	group by CUSTOMERNAME

),
rfm_calc as
(

	select r.*,
		NTILE(4) over (order by Recency desc) rfm_recency,
		NTILE(4) over (order by FREEQUENCY) rfm_frequency,
		NTILE(4) over (order by MONETARYVALUE) rfm_monetary
	from rfm r
)
select c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
case
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
end rfm_segment
from #rfm

-- what products are most often sold together?
--select * from [dbo].[sales_data_sample] where ORDERNUMBER = 10388

select distinct ORDERNUMBER,STUFF(
	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] P
	where ORDERNUMBER in
	(
		select ORDERNUMBER
		from(
			select ORDERNUMBER, count(*) rn
			from [dbo].[sales_data_sample]
			where STATUS = 'shipped' 
			group by ORDERNUMBER 
		)m
		where rn = 3
	) and P.ORDERNUMBER = S.ORDERNUMBER
	for xml path ('')) 
	, 1, 1, '') Prodect_codes
FROM [dbo].[sales_data_sample] S
order by 2 desc

--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc

---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc