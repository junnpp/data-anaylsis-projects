# reference: https://github.com/ptyadana/SQL-Data-Analysis-and-Visualization-Projects
# same data, but slightly different questions and methods

USE instagrams;

# 1. Find the 5 oldest and newest users
# order by registered date ascending
WITH temp AS (
	SELECT
		username,
		created_at,
		DENSE_RANK() OVER(ORDER BY created_at) AS oldest,
		DENSE_RANK() OVER(ORDER BY created_at DESC) AS newest
	FROM Users
)

SELECT *
FROM temp
WHERE oldest <= 5 OR
	  newest <= 5
ORDER BY created_at;

# 2. Ad campaign schedule - when is the most popular weekday to register for new users?
# Most users registered on Sunday (5)
SELECT WEEKDAY(created_at) AS weekd,
	   COUNT(*) AS total_register
FROM Users
GROUP BY WEEKDAY(created_at)
ORDER BY weekd DESC;

# 3. Email markgeting targets - find users who have not yet posted a single post
SELECT username
FROM Users AS t1
LEFT JOIN Photos AS t2
ON t1.id = t2.user_id AND
   t2.id IS NULL;
   
# 4. Who are the top 5 users with the most average number of likes?
SELECT user_id, AVG(total_likes) AS avg_likes
FROM Photos AS t1
LEFT JOIN (
	SELECT photo_id, COUNT(photo_id) AS total_likes
	FROM Likes
	GROUP BY photo_id
) AS t2
ON t1.id = t2.photo_id
GROUP BY user_id
ORDER BY avg_likes DESC
LIMIT 5;

# 5. Bot filter - find users who have liked all photos on the site
SELECT user_id
FROM (
	SELECT user_id, COUNT(*) AS total_likes
	FROM Likes
	GROUP BY user_id
) AS t
WHERE total_likes = (SELECT COUNT(DISTINCT id) FROM Photos);

# 6. Select users who have not made a comment on a photo
SELECT id, username
FROM Users
WHERE id NOT IN (SELECT DISTINCT user_id FROM Comments);

# 7. Find the percentage of users who have commented on every post or never made a comment.
WITH
	every_photo AS (
		SELECT user_id, (SELECT username FROM Users WHERE id = user_id) AS user_name
			FROM (
				SELECT user_id, COUNT(*) AS total_likes
				FROM Likes
				GROUP BY user_id
			) AS t
		WHERE total_likes = (SELECT COUNT(DISTINCT id) FROM Photos)
), 
	none_photo AS (
		SELECT id, username
		FROM Users
		WHERE id NOT IN (SELECT DISTINCT user_id FROM Comments)
)

SELECT
	DISTINCT COUNT(t1.id) OVER() AS total_users,
    AVG(CASE
		WHEN t2.user_id IS NULL THEN 0
        ELSE 1
	END) OVER() AS liked_all_photos_percentage,
    AVG(CASE
		WHEN t3.id IS NULL THEN 0
        ELSE 1
	END) OVER() AS never_liked_percentage
FROM Users AS t1
LEFT JOIN every_photo AS t2
ON t1.id = t2.user_id
LEFT JOIN none_photo AS t3
ON t1.id = t3.id;

 
