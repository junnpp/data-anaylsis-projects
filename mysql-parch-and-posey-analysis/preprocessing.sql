SET SQL_SAFE_UPDATES = 0; # disable safe mode for updating tables

USE Parch;

# 1. change datetime formats - orders table
# getting rid of T and Z from ISO8601 datetime format - occured_at column

# create a new column first
ALTER TABLE orders
ADD COLUMN order_date DATETIME; 

# create a new column order_date from occured_at in datetime format from ISO8601 format
UPDATE orders
SET order_date =
	STR_TO_DATE(
		CONCAT(
			SUBSTRING_INDEX(occured_at, 'T', 1)
            , " "
            , SUBSTRING_INDEX(SUBSTR(occured_at, 1, LENGTH(occured_at) - 5), 'T', -1)
		), '%Y-%m-%d %H:%i:%S'
	);
    
# drop the original column (not using it anymore)
ALTER TABLE orders
DROP COLUMN occured_at;

# 2. Do the same datetime conversion for occured_at column in web_events table

# First, make sure that there is only 0 offset
SELECT
	SUBSTR(occured_at, LENGTH(occured_at) - 3, LENGTH(occured_at)) AS `offset`
    , COUNT(*) AS total
FROM web_events
GROUP BY SUBSTR(occured_at, LENGTH(occured_at) - 3, LENGTH(occured_at));

ALTER TABLE web_events
ADD COLUMN event_date datetime;

# do the datetime conversion
UPDATE web_events
SET event_date = STR_TO_DATE(
		CONCAT(
			SUBSTRING_INDEX(occured_at, 'T', 1)
            , " "
            , SUBSTRING_INDEX(SUBSTR(occured_at, 1, LENGTH(occured_at) - 5), 'T', -1)
		), '%Y-%m-%d %H:%i:%S'
	);

ALTER TABLE web_events
DROP COLUMN occured_at;

/* ----------------------------------------- */

# 3. count the total number of domain name 
SELECT
	RIGHT(website, 3) AS extention
    , COUNT(*) AS num
FROM accounts
GROUP BY 1;

# 4. Is there a strong preference on the first letter of the domain name?
# Companies whose name starts either with letter A or C (n=37) are significantly more than the companies starting with other letters.
SELECT
	LEFT(`name`, 1) AS first_letter
    , COUNT(*) AS num
FROM accounts
GROUP BY 1
ORDER BY 2 DESC, 1;

# 5. Create two groups in accounts table
	# i) compaines with a names starting with a letter
    # ii) companies with a name starting with a number
    # much more companies' name starts with a letter (350 vs. 1)
SELECT
	CASE
		WHEN `name` REGEXP '^[A-Za-z].*' THEN 'letter'
        ELSE 'number'
	END AS first_letter_group
    , COUNT(*) AS num
FROM accounts
GROUP BY 1;

# 6. Proportion of company names start with a vowel
	# about 22.8% company names start with a vowel
SELECT
	AVG(CASE
		WHEN LEFT(name, 1) REGEXP '[AEIOUaeiou]' THEN 1
        ELSE 0
	END) first_letter_vowel
FROM accounts;

# 7. In the `accounts` table, Create first and last name columns from primary_poc and drop primary_poc

ALTER TABLE accounts
ADD COLUMN first_name VARCHAR(255),
ADD COLUMN last_name VARCHAR(255);

UPDATE accounts
SET
	first_name = SUBSTRING_INDEX(primary_poc, " ", 1),
    last_name = SUBSTRING_INDEX(primary_poc, " ", -1);
    
    
ALTER TABLE accounts
DROP COLUMN primary_poc;

# 8. Create an email for each company in the following format: first_name.last_name@`company name`.com

ALTER TABLE accounts
ADD COLUMN email VARCHAR(255);

UPDATE accounts
SET
	email = CONCAT(
				LOWER(first_name)
				, LOWER(last_name)
				, "@"
				, REGEXP_REPLACE(REPLACE(LOWER(name), " ", ""), "[^A-Za-z]", "") -- remove any non-alphabetical letter in company's name
				, ".com"
			);
            
# 9. Create an initial password for each company in the following format:
	# first letter of first_name,
    # last letter of last_name,
    # number of letters in their first name,
    # number of letters in their last name
	# name of the company (capitalized)
    
ALTER TABLE accounts
ADD COLUMN pw VARCHAR(255);

UPDATE accounts
SET
	pw = CONCAT(
		LEFT(first_name, 1)
		, RIGHT(last_name, 1)
        , LENGTH(first_name)
        , LENGTH(last_name)
        , UPPER(name)
    );
    
/* ----------------------------------------- */
    
# 10. Fill misssing values with 0 in the `orders` table
	# we can impute missinv values with 0 because null indicates no order
UPDATE orders
SET
	standard_qty = IFNULL(standard_qty, 0)
    , gloss_qty = IFNULL(gloss_qty, 0)
	, poster_qty = IFNULL(poster_qty, 0)
    , total = IFNULL(total, 0)
    , standard_amt_usd = IFNULL(standard_amt_usd, 0)
    , poster_amt_usd = IFNULL(poster_amt_usd, 0)
    , total_amt_usd = IFNULL(total_amt_usd, 0);
    

            
            
            