WITH combined_apps AS (
        SELECT *, 
		  COALESCE(app_store_apps.price, 0) AS apple_price,
          COALESCE(play_store_apps.price::money::numeric, 0) AS google_price,
		  app_store_apps.rating AS apple_rating,
		  play_store_apps.rating AS google_rating
		FROM   app_store_apps
  INNER JOIN   play_store_apps
         USING(name)  
),
     prices AS (
          SELECT name, apple_price, google_price
		  FROM   combined_apps
),
     higher_prices AS (
       SELECT *,
	   CASE WHEN apple_price > google_price THEN apple_price
	        ELSE google_price END AS higher_price
	   FROM prices
),
	 aquire_prices AS (
	   SELECT *,
	   (CASE WHEN higher_price < 2.50 THEN 25000
	        ELSE higher_price * 10000 END)::money AS aquire_cost
		FROM  higher_prices
),
     rating_minimum AS (
       SELECT name, apple_rating, google_rating,
	          CASE WHEN apple_rating < google_rating THEN apple_rating
			       ELSE google_rating END AS lowest_rating
	   FROM   combined_apps	   
),
     rounded_ratings AS (
       SELECT *, ROUND(lowest_rating/0.25) * 0.25 AS rounded_rating
	   FROM   rating_minimum
),
     ratings_and_prices AS (
      SELECT *
	  FROM   aquire_prices
	  JOIN   rounded_ratings
	    USING(name)
),
     final_cte AS (
	   SELECT rounded_rating * 24 + 12 AS longevity_months
	          ,*
	   FROM   ratings_and_prices
)
SELECT   DISTINCT name,
         CONCAT(ROUND((longevity_months * 9000 - aquire_cost::numeric)/1000000, 3),
		 ' million dollars' )
         AS net_income, aquire_cost, rounded_rating, longevity_months::integer 
FROM     final_cte
ORDER BY net_income DESC, name
LIMIT 10
-- LIMIT 110 rows 8-110 all have the same net income
--ORDER BY rounded_ratings DESC,aquire_cost ASC
--SELECT   *
--FROM     aquire_prices
--ORDER BY aquire_cost DESC
;  -- The EO BAR (#7 stands out)