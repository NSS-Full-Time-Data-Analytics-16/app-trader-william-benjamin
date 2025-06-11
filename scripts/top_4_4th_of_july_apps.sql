SELECT DISTINCT price::money::numeric
FROM   play_store_apps
;


WITH combined_apps AS (
        SELECT *, 
		  COALESCE(app_store_apps.price, 0) AS apple_price,
          COALESCE(play_store_apps.price::money::numeric, 0) AS google_price,
		  app_store_apps.rating AS apple_rating,
		  play_store_apps.rating AS google_rating,
		  primary_genre AS apple_genre, genres AS google_genre,
		  category AS google_category
		FROM   app_store_apps
  INNER JOIN   play_store_apps
         USING(name)  
),
     prices AS (
          SELECT name, apple_price, google_price,
		         apple_genre, google_genre, google_category
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
SELECT   DISTINCT name, (longevity_months * 9000 - aquire_cost::numeric)::money 
         AS net_income, --aquire_cost, rounded_rating, longevity_months::integer,
		 apple_genre, google_genre, google_category
FROM     final_cte
WHERE    name ILIKE '%Facebook'
      OR name ILIKE '%Paprika%'
	  OR name ILIKE '%Airbnb%'
	  OR name ILIKE '%Fly%Delta%'
ORDER BY net_income DESC, name
-- LIMIT 110
--ORDER BY rounded_ratings DESC,aquire_cost ASC
--SELECT   *
--FROM     aquire_prices
--ORDER BY aquire_cost DESC
;  -- The EO BAR (#7 stands out)