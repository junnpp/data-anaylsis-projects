
CREATE DATABASE IF NOT EXISTS Parch;
USE Parch;

CREATE TABLE `web_events` (
    `id` INT,
    `account_id` INT,
    `occured_at` VARCHAR(255),
    `channel` VARCHAR(255),
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `accounts` (
    `id` INT,
    `name` VARCHAR(255),
    `website` VARCHAR(255),
    `lat` DOUBLE,
    `long` DOUBLE,
    `primary_poc` VARCHAR(255),
    `sales_rep_id` INT,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `orders` (
    `id` INT,
	`account_id` INT,
	`occured_at` VARCHAR(255), 
    `standard_qty` INT,
    `gloss_qty` INT,
    `poster_qty` INT,
    `total` DOUBLE,
    `standard_amt_usd` DOUBLE,
    `gloss_amt_usd` DOUBLE,
    `poster_amt_usd` DOUBLE,
    `total_amt_usd` DOUBLE,
    PRIMARY KEY (
        `id`
    )
);

SET GLOBAL local_infile=1;

LOAD DATA LOCAL INFILE '~/Desktop/project/data-analysis-projects/mysql-parch-and-posey-analysis/data/orders.csv'
INTO TABLE Parch.orders FIELDS TERMINATED BY ','
ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

CREATE TABLE `sales_reps` (
    `id` INT,
    `name` VARCHAR(255),
    `region_id` INT,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `region` (
    `id` INT,
    `name` VARCHAR(255),
    PRIMARY KEY (
        `id`
    )
);
