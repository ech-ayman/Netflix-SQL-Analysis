DROP TABLE IF EXISTS Netflix_movies;
CREATE TABLE Netflix_movies (
    show_id VARCHAR PRIMARY KEY,
    type VARCHAR,
    title VARCHAR,
    director VARCHAR,
    actors VARCHAR,
    country VARCHAR,
    date_added VARCHAR,
    release_year INT,
    rating VARCHAR,
    duration VARCHAR,
    listed_in VARCHAR,
    description TEXT
);
-- QUESTIONS :
-- Question 01 :
-- 1. Count the number of Movies VS TV shows
SELECT
    type,
    count(type)
FROM Netflix_movies
group by type;

-- 2. Find the most common rating for Movies and TV shows
SELECT
    type,
    rating,
    count
    FROM
    (SELECT type,
            rating,
            count(rating) AS count,
            RANK() OVER (PARTITION BY type ORDER BY count(rating) DESC) AS Ranking
     FROM Netflix_movies
     GROUP BY 1, 2 ) AS tab1
WHERE Ranking = '1'
GROUP BY 1,2,3;

-- 3. List all movies released in a specific year (e.g., 2008)
SELECT
    title,
    type,
    release_year
FROM Netflix_movies
WHERE
    release_year = '2008'
  AND
    type = 'Movie';

-- 4. Find the top 5 countries with the most content on Netflix
SELECT
    TRIM(unnest(string_to_array(country, ',' ))) AS single_country,
    count(*) AS total_content

FROM Netflix_movies
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- 5. Identify the longest movie
SELECT
    title,
    duration
FROM
    (SELECT
        title,
        TRIM(replace(duration, 'min', ''))::INTEGER AS nbr_duration,
        duration
    FROM Netflix_movies
    WHERE type = 'Movie' AND duration IS NOT NULL
    ORDER BY nbr_duration DESC) AS T3
LIMIT 1;

-- 6. Find content added in the last 5 years
SELECT
    title,
    to_date(date_added, 'Month DD, YYYY') AS real_date
FROM Netflix_movies
WHERE
    to_date(date_added, 'Month DD, YYYY') >= (current_date - INTERVAL '5 YEARS')
order by 2;

-- 7. Find all the movies/TV shows by director 'Masahiko Murata'!
SELECT DISTINCT
    *
FROM
(SELECT
    title,
    type,
    TRIM(unnest(string_to_array(director, ','))) AS the_director
FROM Netflix_movies) SUB
WHERE the_director = 'Masahiko Murata';

-- 8. List all TV shows with more than 5 seasons
-- methode 1:
SELECT
    title,
    type,
    duration
FROM
(SELECT
    title,
    type,
    cast(TRIM(replace(replace(duration , 'Seasons', ''), 'Season', '')) AS INTEGER ) AS new_duration,
    duration
FROM Netflix_movies
WHERE type = 'TV Show') SUB
WHERE new_duration > 5;

-- methode 2 :
SELECT
    title,
    type,
    duration
FROM Netflix_movies
WHERE split_part(duration, ' ', 1)::INTEGER > 5 AND type = 'TV Show';

-- 9. Count the number of content items in each genre
-- Subquery :
SELECT distinct
    genre,
    count(genre) AS total_content
FROM (
SELECT
    trim(unnest(string_to_array(listed_in, ','))) AS genre
FROM Netflix_movies) Subquery
group by 1
order by 2 desc;
-- CTE : Common Table Expression
with genre_table as (
    SELECT  trim(unnest(string_to_array(listed_in, ','))) AS genre
    FROM Netflix_movies
)
select
    genre,
    count(genre) AS total_content
from genre_table
group by 1
order by 2 desc
;

-- 10. Find each year and the percentage of Morocco content released on Netflix.
-- Return the top 3 years with the highest percentage.
WITH single_countries AS (
    SELECT
        trim(unnest(string_to_array(country, ','))) AS the_country,
        release_year
    FROM Netflix_movies
    )
SELECT
    the_country,
    release_year,
    count(*) AS yearl_content,
    round(count(*)::numeric/(SELECT count(*) FROM single_countries WHERE The_country = 'Morocco')::numeric*100.0 ,2) AS pct_content
FROM single_countries
WHERE The_country = 'Morocco'
GROUP BY 1, 2
ORDER BY 4 DESC
LIMIT 3;

-- 11. List all movies that are documentaries
-- METHOD 1 :
WITH single_genre AS (SELECT
    title,
    type,
    trim(unnest(string_to_array(listed_in, ','))) as genre
FROM Netflix_movies)
SELECT *
FROM single_genre
WHERE type = 'Movie' AND genre = 'Documentaries';
-- Method 2 :
SELECT
    title,
    type,
    listed_in
FROM Netflix_movies
WHERE listed_in ILIKE '%Documentaries%';

-- 12. Find all content without a director
SELECT
    title
FROM Netflix_movies
WHERE director ISNULL ;

-- 13. Find how many movies actor 'Henry Cavill' appeared in last 10 years!
SELECT
    title,
    type,
    actors,
    release_year
FROM Netflix_movies
WHERE actors ILIKE '%Henry Cavill%' AND release_year > extract(YEAR FROM current_date) - 10
ORDER BY release_year DESC;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in the United States.
-- CTE "1" : actor split
WITH actor_split AS (
SELECT
    show_id,
    trim(unnest(string_to_array(actors, ','))) AS actor
FROM Netflix_movies
WHERE type = 'Movie'),
-- CTE "2" : country split
country_split AS (
SELECT
    show_id,
    trim(unnest(string_to_array(country, ','))) AS the_country
FROM Netflix_movies
WHERE type = 'Movie')
-- Query : JOIN CTE "1" ON CTE "2"
SELECT
    a.actor,
    count(a.actor) AS total_movies
FROM actor_split a
JOIN country_split c ON a.show_id = c.show_id
WHERE c.the_country = 'United States'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Question 15:
-- Categorize the content based on the presence of the keywords 'kill' or 'violence' in the description field.
-- Label content containing these keywords as 'Bad' and all other content as 'Good'.
-- Count how many items fall into each category.

WITH content_category AS (SELECT title,
                                 CASE
                                      WHEN description ~* '\m(violence|violent|violently)\M'
                                               OR
                                           description ~* '\mkill(er|s|ing|ers|ed)?\M' THEN 'bad'
                                      ELSE 'good'
                                      END content,
                                 description
                          FROM Netflix_movies)
SELECT
    content,
    count(content) AS total_items
FROM content_category
GROUP BY content;

 -- finish of project :)





