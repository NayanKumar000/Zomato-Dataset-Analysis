-- ------------ ZOMATO RESTAURANT ANALYSIS ------------- ----------
/* TABLES USED */
SELECT * FROM MAIN; -- MAIN TABLE
SELECT * FROM COUNTRY; -- COUNTRY TABLE
SELECT * FROM CURRENCY; -- CURRENCY TABLE
SELECT * FROM CALENDAR; -- CALENDAR TABLE

/* CALENDAR TABLE */

CREATE TABLE calendar AS
SELECT 
  STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d') AS Datekey_Opening,
  YEAR(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) AS Year,
  MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) AS MonthNo,
  MONTHNAME(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) AS MonthFullName,
  CONCAT('Q', QUARTER(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d'))) AS Quarter,
  DATE_FORMAT(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d'), '%Y-%b') AS YearMonth,
  DAYOFWEEK(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) AS WeekdayNo,
  DAYNAME(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) AS WeekdayName,
  
  -- Financial Month (April=1 ... March=12)
  CASE 
    WHEN MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) >= 4 
         THEN MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) - 3
    ELSE MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) + 9
  END AS FinancialMonth,

  -- Financial Quarter
  CONCAT('FQ', 
    CASE 
      WHEN MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) BETWEEN 4 AND 6 THEN 1
      WHEN MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) BETWEEN 7 AND 9 THEN 2
      WHEN MONTH(STR_TO_DATE(CONCAT(`Year Opening`, '-', `Month Opening`, '-', `Day Opening`), '%Y-%m-%d')) BETWEEN 10 AND 12 THEN 3
      ELSE 4
    END
  ) AS FinancialQuarter
FROM main;


-- Converting the Average cost for 2 column into USD dollars 
UPDATE main m left JOIN currency cr on m.Currency=cr.Currency 
SET m.avg_cost_USD = m.Average_Cost_for_two*cr.USD_rate;

-- Number of restaurants based on city 
select city,count(RestaurantID) rest_count from main group by city order by rest_count desc;

-- Number of restaurants based on country
select cn.Countryname,count(RestaurantID) rest_count
from main m left join country cn on m.CountryCode=cn.CountryID
group by cn.Countryname order by rest_count desc;

-- Numbers of Resturants opening based on Year , Quarter , Month
SELECT 
    cal.Year,
    cal.Quarter,
    cal.MonthFullName AS month_name,
    COUNT(*) AS number_of_restaurants
FROM main z
JOIN calendar cal
    ON cal.Datekey_Opening = STR_TO_DATE(CONCAT(z.`Year Opening`, '-', z.`Month Opening`, '-', z.`Day Opening`), '%Y-%m-%d')
GROUP BY cal.Year, cal.Quarter, cal.MonthFullName
ORDER BY cal.Year, cal.Quarter, cal.MonthFullName;

-- Count of Resturants based on Average Ratings
SELECT Rating AS average_rating, COUNT(*) AS restaurant_count
FROM main
GROUP BY Rating
ORDER BY Restaurant_count DESC;

-- Creating buckets based on Average Price of reasonable size and restaurants count falls in each buckets
SELECT 
    CASE
      WHEN Average_Cost_for_two < 500 THEN '(<500) : Low'
      WHEN Average_Cost_for_two BETWEEN 500 AND 2000 THEN '(500-2000) : Medium'
      WHEN Average_Cost_for_two BETWEEN 2001 AND 5000 THEN '(2001-5000) : High'
      ELSE '(>5000) : Luxury'
	END AS PRICE_BUCKET,
    COUNT(*) AS Restaurant_Count
FROM main
Group By PRICE_BUCKET;

-- Percentage of Resturants based on "Has_Table_booking"
SELECT 
    Has_Table_booking,
    COUNT(*) AS table_book_rest_count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main)), 2) AS percentage
FROM main
GROUP BY Has_Table_booking;

-- Percentage of Resturants based on "Has_Online_delivery"
SELECT 
    Has_Online_delivery,
    COUNT(*) AS online_del_rest_count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main)), 2) AS percentage
FROM main
GROUP BY Has_Online_delivery;

/*Insights based on Cusines, City, Ratings */

-- Overall restaurants average rating:
select round(avg(rating),2) avg_rating from main; 

-- Top Cuisine available in most of the restaurants
select Cuisines Top_cuisine,count(RestaurantID) restaurant_count 
from main group by cuisines limit 1;
 
-- Top/Bottom 5 Cities based on average rating
select city "Top 5 cities by avg_rating",round(avg(rating),2) avg_rating 
from main group by city order by avg_rating desc limit 5;

select city "Bottom 5 cities by avg_rating",round(avg(rating),2) avg_rating 
from main group by city order by avg_rating asc limit 5;

-- most expensive city per country
SELECT cn.Countryname,m.City,max(Average_Cost_for_two) cost 
from main m join country cn ON m.CountryCode=cn.CountryID
group by city, cn.Countryname,price_bucket
order by cost desc;

-- Top rated cuisine
select m.cuisines, max(rating) rating, cn.Countryname from main m join country cn on m.CountryCode=cn.CountryID
-- where Countryname='india'
group by cn.Countryname,Cuisines order by rating desc;

-- Top country with MAX number of restaurants 
Select  cn.countryname,count(m.RestaurantID) restaurant_count  
from main m left join country cn on m.CountryCode=cn.countryid 
group by cn.countryname order by restaurant_count desc limit 1;

-- Country with LEAST number of restaurants
Select  cn.countryname,count(m.RestaurantID) restaurant_count  
from main m left join country cn on m.CountryCode=cn.countryid 
group by cn.countryname order by restaurant_count asc limit 1;