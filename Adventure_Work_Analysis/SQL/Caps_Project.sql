CREATE DATABASE cap_project;
USE cap_project;

SELECT * FROM dim_date;               	# Date Table 
SELECT * FROM fact_internetsales;		# Fact table(sales)
SELECT * FROM dim_productcategory;		# Category Table
SELECT * FROM dim_product;				# Product Table
SELECT * FROM dim_geography;			# Geography Table ####
SELECT * FROM dim_productsubcategory;   # Subcategory Table
SELECT * FROM dim_customer;				# Customer Table

# 1) Total number of customers
SELECT 
	COUNT(*) Total_Customer 
FROM dim_customer;

# 2) Total number of orders placed
SELECT 
	COUNT(DISTINCT salesordernumber) AS Total_Orders 
FROM fact_internetsales;

# 3) Total production cost
SELECT 
	round(sum(totalproductcost),2) AS Production_cost 
FROM fact_internetsales;

# 4) Average order value
SELECT 
	round(AVG(order_total),2) avg_order_value
FROM (
	SELECT salesordernumber, 
		SUM(SalesAmount) AS order_total
    FROM fact_internetsales
    GROUP BY salesordernumber) t;

# 5) Total profit
SELECT 
	round(SUM(profit), 2)Total_Profit 
FROM fact_internetsales;

# 6) Profit margin percentage
SELECT 
	round(sum(profit)/SUM(totalproductcost)*100 ,2) AS Profit_percentage 
FROM fact_internetsales;

# 7) Total Sales Amount by product with tax and shipment charges
SELECT  
	f.productkey, 
	p.ProductName, 
    g.CountryName, 
    round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_geography g
	ON f.SalesTerritoryKey = g.SalesTerritoryKey
GROUP BY g.CountryName, p.ProductName, f.productkey
ORDER BY g.CountryName;

# 8) Total Sales Amount by Product Subcategory with tax and shipment charges
SELECT  
	s.ProductSubcategoryName, 
	round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_productsubcategory s
	ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
GROUP BY s.ProductSubcategoryName;

# 9) Total Sales Amount by Product Category with tax and shipment charges
SELECT  
	c.ProductCategoryName, 
	round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_productsubcategory s
	ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
LEFT JOIN dim_productcategory c
	ON s.ProductCategoryKey = c.ProductCategoryKey
GROUP BY c.ProductCategoryName;

# 10) Top 3 subcategory per region
SELECT  
	g.countryname, 
	round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_geography g
	ON f.SalesTerritoryKey = g.SalesTerritoryKey
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_productsubcategory s
	ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
GROUP BY g.countryname
ORDER BY SUM(f.TotalSalesAmount)  DESC
LIMIT 3;

# 11) Top 3 year of highest Sales
SELECT 
	d.Calendaryear,
    ROUND(SUM(f.salesamount), 2) AS total_sales
FROM fact_internetsales f
LEFT JOIN dim_date d
	ON f.OrderDatekey = d.datekey
GROUP BY d.Calendaryear
ORDER BY total_sales DESC
LIMIT 3; 

# 12) Top 3 months with highest sales
SELECT 
	d.Monthname,
    ROUND(SUM(f.salesamount), 2) AS total_sales
FROM fact_internetsales f
LEFT JOIN dim_date d
     ON f.OrderDatekey = d.datekey
GROUP BY d.MonthName
ORDER BY total_sales DESC
LIMIT 3; 

# 13) Top 3 months with lowest sales
SELECT 
	d.Monthname,
    ROUND(sum(f.salesamount), 2) AS total_sales
FROM fact_internetsales f
LEFT JOIN dim_date d
     ON f.OrderDatekey = d.datekey
GROUP BY d.MonthName
ORDER BY total_sales 
LIMIT 3; 

# 14) Average monthly Sales
SELECT 
	MonthName, 
	ROUND(AVG(monthly_sales), 2) AS avg_monthly_sales
FROM (
    SELECT 
		d.Calendaryear,
        d.MonthName,
		d.monthnumberofyear,
		round(SUM(f.salesamount),2) AS monthly_sales
    FROM fact_internetsales f
    LEFT JOIN dim_date d
         ON f.OrderDatekey = d.datekey
    GROUP BY d.Calendaryear, d.monthName,d.monthnumberofyear
) monthly_summary
GROUP BY MonthName, monthnumberofyear
ORDER BY MonthNumberofyear;

# 15) YOY percentage Growth in sales
SELECT
    d.Calendaryear,
    round(SUM(f.salesamount),2) AS total_sales,
    LAG(round(SUM(f.salesamount),2)) OVER (ORDER BY d.calendaryear) AS prev_year_sales,
    ROUND(( SUM(f.salesamount)
            - LAG(SUM(f.salesamount)) OVER (ORDER BY d.calendaryear)
        )
        / LAG(SUM(f.salesamount)) OVER (ORDER BY d.calendaryear)
        * 100,
        2
    ) AS yoy_growth_pct
FROM fact_internetsales f
JOIN dim_date d
     ON f.orderdatekey = d.datekey
GROUP BY d.calendaryear
ORDER BY d.calendaryear;

# 16) Quarter contributes the highest revenue
SELECT 
    d.calendarquarter,
    ROUND(SUM(f.salesamount), 2) AS total_revenue
FROM fact_internetsales f
JOIN dim_date d
     ON f.orderdatekey = d.datekey
GROUP BY d.calendarquarter
ORDER BY total_revenue DESC
LIMIT 1;

# 17) Country that generates the highest sales
SELECT 
	g.CountryName, 
    round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_geography g
	ON f.SalesTerritoryKey = g.SalesTerritoryKey
GROUP BY g.CountryName
ORDER BY Total_Sales_Amount DESC
LIMIT 1 ;

# 18) State/province with the most customers
WITH customer_state AS (
	SELECT 
		g.countryname, 
        g.Statename, 
        count(c.customerkey) total_customers
    FROM dim_customer c
    LEFT JOIN dim_geography g
		ON c.geographyKey = g.geographykey
    GROUP BY g.countryname, g.statename 
    )
    
SELECT countryname, Statename, total_customers
FROM (SELECT *, 
		ROW_NUMBER() OVER(PARTITION BY countryname ORDER BY total_customers DESC) as rnk
		FROM customer_state) t
WHERE rnk = 1
ORDER BY countryname DESC;

# 19) City contributes the least revenue per state
WITH customer_state AS (
	SELECT 
		g.countryname, 
		g.Statename, 
        g.city, 
        round(sum(f.salesamount),2) total_sales
    FROM fact_internetsales f
    LEFT JOIN dim_geography g
		ON f.salesterritorykey = g.salesterritorykey
    GROUP BY g.countryname, g.statename , g.city
    )
SELECT 
	countryname, 
    Statename,
    city, total_sales
FROM (
	SELECT * , 
		ROW_NUMBER() OVER(PARTITION BY statename ORDER BY total_sales ASC) as rnk
		FROM customer_state) t
WHERE rnk <= 3
ORDER BY statename, total_sales ;    
	
# 20) Country whth the highest profit margin
SELECT 
	g.countryname, 
    round(sum(f.profit),2) total_profit
FROM fact_internetsales f
LEFT JOIN dim_geography g
	ON f.salesterritorykey = g.salesterritorykey
GROUP BY g.countryname
ORDER BY total_profit DESC
LIMIT 1;

# 21) Country with the highest shipping cost
SELECT 
	g.countryname, 
   round(sum(f.freight),2) shipping_cost
FROM fact_internetsales f
LEFT JOIN dim_geography g
	ON f.salesterritorykey = g.salesterritorykey
GROUP BY g.countryname
ORDER BY shipping_cost DESC
LIMIT 1;

# 22) Top 10 customers by revenue per country
WITH top_customer AS (
	SELECT 	
		c.name, 
		g.statename, 
        g.countryname, 
        round(sum(f.salesamount),2) Total_sales
	FROM fact_internetsales f
	LEFT JOIN dim_customer c
		ON f.customerkey = c.customerkey
	LEFT JOIN dim_geography g
		ON c.geographykey = g.geographykey
	GROUP BY c.name, g.statename, g.countryname
    )
    
SELECT countryname, statename, name
FROM (
	SELECT *, 
		ROW_NUMBER() OVER(PARTITION BY statename ORDER BY total_sales DESC) AS rnk
	FROM top_customer) t
WHERE rnk <=10
GROUP BY name, statename, countryname
ORDER BY countryname, statename DESC;

# 23) Gender distribution on total sales sales
SELECT 
	c.gender, 
    round(sum(f.salesamount),2) Total_sales
FROM fact_internetsales f
LEFT JOIN dim_customer c
	ON f.customerkey = c.customerkey
GROUP BY c.gender
ORDER BY Total_sales DESC;

# 24) Sales distribution by marital status.
SELECT 
	c.maritalstatus, 
    round(sum(f.salesamount),2) Total_sales
FROM fact_internetsales f
LEFT JOIN dim_customer c
	ON f.customerkey = c.customerkey
GROUP BY c.maritalstatus
ORDER BY Total_sales DESC;

# 25) Top 10 product generated the highest revenue
SELECT  
	f.productkey, 
    p.ProductName, 
    round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, f.productkey
ORDER BY total_sales_amount DESC
LIMIT 10;

# 26) Top 10 product that sold highest quantity
SELECT  
	f.productkey, 
    p.ProductName, 
    round(SUM(f.orderquantity),2) Total_quantity
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, f.productkey
ORDER BY Total_quantity DESC
LIMIT 10;

# 27) 10 product that sold least quantity
SELECT  
	f.productkey, 
    p.ProductName, 
    round(SUM(f.orderquantity),2) Total_quantity
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, f.productkey
ORDER BY Total_quantity ASC
LIMIT 10;

# 28) 10 product with least profit margin
SELECT  
	f.productkey, 
    p.ProductName, 	
    round(SUM(f.profit), 2) Total_profit
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, f.productkey
ORDER BY Total_profit DESC
LIMIT 10;

# 29) Product category total revenue
SELECT  
	c.ProductCategoryName, 
    round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_productsubcategory s
	ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
LEFT JOIN dim_productcategory c
	ON s.ProductCategoryKey = c.ProductCategoryKey
GROUP BY c.ProductCategoryName
ORDER BY total_sales_amount DESC;

# 30) Top 10 Best performing subcategories.
SELECT  	
	s.ProductsubCategoryName, 
    round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_productsubcategory s
	ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
GROUP BY s.ProductsubCategoryName
ORDER BY total_sales_amount DESC
LIMIT 10;

# 31) 10 least performing subcategories.
SELECT  
	s.ProductsubCategoryName, 	
    round(SUM(f.TotalSalesAmount),2) Total_Sales_Amount
FROM fact_internetsales f
LEFT JOIN dim_product p
	ON f.ProductKey = p.ProductKey
LEFT JOIN dim_productsubcategory s
	ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
GROUP BY s.ProductsubCategoryName
ORDER BY total_sales_amount ASC
LIMIT 10;

# 32) Shipping cost by region.
SELECT 
	g.countryname, 
    round(avg(f.freight),2) shipping_cost
FROM fact_internetsales f
LEFT JOIN dim_geography g
	ON f.salesterritorykey = g.salesterritorykey
GROUP BY g.countryname
ORDER BY shipping_cost DESC;

# 33) Yearly tax trends.
SELECT
    d.calendaryear,
    ROUND(SUM(f.taxamt), 2) AS total_tax
FROM fact_internetsales f
JOIN dim_date d
     ON f.orderdatekey = d.datekey
GROUP BY d.calendaryear
ORDER BY d.calendaryear;

# 34) Profit by country.
SELECT 
	g.CountryName, 	
    round(SUM(f.profit),2) Total_profit
FROM fact_internetsales f
LEFT JOIN dim_geography g
	ON f.SalesTerritoryKey = g.SalesTerritoryKey
GROUP BY g.CountryName
ORDER BY Total_profit DESC;
