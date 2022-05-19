--https://mode.com/sql-challenge/
--Using these 4 tables in the Mode Public Warehouse:
--sqlchallenge1.accounts, sqlchallenge1.sales_reps, sqlchallenge1.orders, sqlchallenge1.region

--BASIC EXERCISE #1: List the account name with the longest website url.
--my answer: United Continental Holdings (website is 33 characters)

SELECT name, website, LENGTH(website) AS website_chars
  FROM sqlchallenge1.accounts
    ORDER BY 3 DESC

--BASIC EXERCISE #2: How many sales reps have the letter 'e' in their names?
--my answer: 40

SELECT COUNT(*)
  FROM sqlchallenge1.sales_reps
    WHERE name ILIKE '%e%'

--BASIC EXERCISE #3: What is the alphabetically first account name that
--contains an ampersand ("&")?
--my answer: Air Products & Chemicals

SELECT name
  FROM sqlchallenge1.accounts
    WHERE name ILIKE '%&%'
    ORDER BY 1

--BASIC EXERCISE #4: What is the id of the sales rep that sold the last order in May 2015?
--my answer: 321760
SELECT orders.occurred_at, accounts.sales_rep_id
  FROM sqlchallenge1.orders orders
    JOIN sqlchallenge1.accounts accounts
      ON orders.account_id = accounts.id
    WHERE orders.occurred_at BETWEEN '2015-05-01' AND '2015-06-01'
    ORDER BY 1 DESC
    
--BASIC EXERCISE #5: How many sales reps represent the Northeast region?
--my answer: 21
SELECT COUNT(*)
  FROM sqlchallenge1.sales_reps reps
    JOIN sqlchallenge1.region regions
      ON reps.region_id = regions.id
  WHERE regions.name = 'Northeast'
  

--INTERMEDIATE EXERCISE #1: Which region has the
--lowest proportion [ratio?] of sales reps to accounts?
--my answer: West
SELECT region_rep.region, region_rep.rep_count, SUM(rep_acct.acct_count) AS accounts,
      region_rep.rep_count / SUM(rep_acct.acct_count) AS rep_to_acct
  FROM (
      SELECT regions.name AS region,
            regions.id AS reg_id,
            COUNT(reps.name) AS rep_count
        FROM sqlchallenge1.region regions
          JOIN sqlchallenge1.sales_reps reps
            ON regions.id = reps.region_id
        GROUP BY 1, 2
  ) region_rep
    JOIN (
      SELECT reps.name AS rep,
          reps.region_id AS regionID,
          COUNT(accounts.id) AS acct_count
      FROM sqlchallenge1.accounts accounts
      JOIN sqlchallenge1.sales_reps reps
        ON reps.id = accounts.sales_rep_id
       GROUP BY 1, 2
    ) rep_acct
    ON region_rep.reg_id = rep_acct.regionID
    GROUP BY 1, 2

--INTERMEDIATE EXERCISE #2: Among sales reps Tia Amato, Delilah Krum, and Soraya Fulton,
--which one had accounts with the greatest total quantity ordered (not USD) in September 2016?
--my answer: Tia Amato
SELECT reps.name, SUM(sub.total_qty)
  FROM sqlchallenge1.sales_reps reps
    JOIN (
          SELECT accounts.sales_rep_id AS rep,
                accounts.name AS acct,
                SUM(orders.total) AS total_qty
            FROM sqlchallenge1.accounts accounts
              JOIN sqlchallenge1.orders orders
                ON accounts.id = orders.account_id
              WHERE orders.occurred_at BETWEEN '2016-09-01' AND '2016-10-01'
              GROUP BY 2, 1
          ) sub
      ON reps.id = sub.rep
  WHERE reps.name IN ('Tia Amato', 'Delilah Krum', 'Soraya Fulton')
  GROUP BY 1 --alt is no grouping and sum aggr, Tia is still the answer (?)
  ORDER BY 2 DESC

--INTERMEDIATE EXERCISE #3: Of accounts served by sales reps in the Northeast,
--one account has never bought any posters. Which company (enter 'name')?
--my answer: Exxon Mobil

--shortcut:
SELECT  accounts.name,
        SUM(orders.poster_qty)
    FROM sqlchallenge1.orders AS orders
      JOIN sqlchallenge1.accounts AS accounts
        ON orders.account_id = accounts.id
      JOIN sqlchallenge1.sales_reps AS reps
        ON accounts.sales_rep_id = reps.id
      JOIN sqlchallenge1.region AS regions
        ON reps.region_id = regions.id
  WHERE reps.region_id = 1
  GROUP BY 1
  ORDER BY 2
  
--long cut and specific:
SELECT nerep.region,
      repacct.company,
      repacct.total_poster_qty
  FROM (
      SELECT reps.id AS rep, region.name AS region
        FROM sqlchallenge1.sales_reps reps
          JOIN sqlchallenge1.region region
            ON reps.region_id = region.id
          WHERE region.name = 'Northeast'
      ) nerep
    JOIN (
        SELECT accounts.sales_rep_id AS rep,
              accounts.name AS company,
              SUM(orders.poster_qty) AS total_poster_qty
          FROM sqlchallenge1.accounts accounts
            JOIN sqlchallenge1.orders orders
              ON accounts.id = orders.account_id
          GROUP BY 2, 1
        ) repacct
      ON nerep.rep = repacct.rep
    WHERE repacct.total_poster_qty = 0
    ORDER BY 2

--INTERMEDIATE EXERCISE #4: How many accounts have never ordered Poster?
--my answer: 6
SELECT COUNT(CASE WHEN sub.posters = 0 THEN 1 END) AS no_posters
  FROM (
      SELECT accounts.name,
            SUM(COALESCE(orders.poster_qty, 0)) AS posters
        FROM sqlchallenge1.accounts accounts
          FULL JOIN sqlchallenge1.orders orders
            ON accounts.id = orders.account_id
          GROUP BY 1
      ) sub

--INTERMEDIATE EXERCISE #5: What is the most common first name for Account primary POCs?
--my answer: Jodee
SELECT poc_first_name,
      COUNT(poc_first_name)
  FROM (
      SELECT LEFT(primary_poc, POSITION(' ' IN primary_poc)-1) AS poc_first_name
        FROM sqlchallenge1.accounts
      ) sub
    GROUP BY 1
    ORDER BY 2 DESC


--ADVANCED EXERCISE #1: For the West region, which month (list the full name)
--had the highest percent of poster orders by count during 2015?
--my answer: November
SELECT acctor.month,
      SUM(acctor.poster_ct)
  FROM (
        SELECT reps.id AS rep, regions.name AS region
          FROM sqlchallenge1.sales_reps reps
            JOIN sqlchallenge1.region regions
              ON regions.id = reps.region_id
          WHERE regions.name = 'West'
        ) regrep
    JOIN (
          SELECT EXTRACT('month' FROM orders.occurred_at) AS month,
                accounts.sales_rep_id AS rep,
                SUM(orders.poster_qty) AS poster_ct
            FROM sqlchallenge1.orders orders
              JOIN sqlchallenge1.accounts accounts
                ON accounts.id = orders.account_id
                WHERE EXTRACT('year' FROM orders.occurred_at) = 2015
                GROUP BY 1, 2
          ) acctor
      ON regrep.rep = acctor.rep
      GROUP BY 1
      ORDER BY 2 DESC

--ADVANCED EXERCISE #2: Starting from the time of their first order,
--which sales rep reached $100,000 in total sales the fastest in terms of time?
--List the id for this sales rep.
--my answer: 321900 and correct BUT script is wonky. revisit and try to figure out better approach!!
SELECT rep,
      last_date - first_date AS road_to100k,
      last_date, first_date, runningct,
      MAX(runningct) OVER (PARTITION BY rep) AS hundredk
  FROM (
        SELECT accounts.sales_rep_id AS rep,
              orders.total_amt_usd AS total_amt,
              orders.occurred_at AS time,
              SUM(orders.total_amt_usd) OVER
                (PARTITION BY accounts.sales_rep_id ORDER BY orders.occurred_at)
                AS runningct,
              MIN(orders.occurred_at) OVER
                (PARTITION BY accounts.sales_rep_id ORDER BY orders.occurred_at)
                AS first_date,
              MAX(orders.occurred_at) OVER
                (PARTITION BY accounts.sales_rep_id ORDER BY orders.occurred_at)
                AS last_date
          FROM sqlchallenge1.orders orders
            JOIN sqlchallenge1.accounts accounts
              ON orders.account_id = accounts.id
        ) sub
  WHERE runningct <= 100000
    AND first_date != last_date
  GROUP BY 1, 3, 4, 5
  ORDER BY 2

--ADVANCED EXERCISE #3: For sales rep with at least 2 orders,
--what is the name of the sales rep who went the longest time
--between their first and second order?
--my answer: Eugena Esser
--self-note: find a way to get rid of the nulls post-op. join?

SELECT reps.name,
       time - LAG(time, 1) OVER
        (PARTITION BY sub.rep ORDER BY sub.ranking) AS difference,
        sub.rep, sub.ranking, sub.time
  FROM (
        SELECT accounts.sales_rep_id AS rep,
              orders.id AS orders,
              orders.occurred_at AS time,
              DENSE_RANK() OVER
                (PARTITION BY accounts.sales_rep_id ORDER BY orders.occurred_at)
                  AS ranking
          FROM sqlchallenge1.orders orders
            FULL JOIN sqlchallenge1.accounts accounts
              ON orders.account_id = accounts.id
        ) sub
    JOIN sqlchallenge1.sales_reps reps
      ON sub.rep = reps.id
  WHERE sub.ranking < 3
  GROUP BY 1, 3, 4, 5
  ORDER BY 2 DESC

--ADVANCED EXERCISE #4: How many sales reps had at least 9 orders
--before surpassing $10k cumulative sales?
--my answer: 2
SELECT rep,
      COUNT(running_amt) AS orders_before_10k
  FROM (
        SELECT accounts.sales_rep_id AS rep,
              SUM(total_amt_usd) OVER
                (PARTITION BY accounts.sales_rep_id ORDER BY occurred_at)
                AS running_amt
          FROM sqlchallenge1.orders orders
            JOIN sqlchallenge1.accounts accounts
              ON orders.account_id = accounts.id
        ) sub
    WHERE running_amt < 10000
    GROUP BY 1
    ORDER BY 2 DESC

--more goal-specific (count how many reps)
SELECT COUNT(CASE WHEN counted.orders_before_10k >= 9 THEN 1 END)
        AS reps_with_9orders_before10k
  FROM (
        SELECT rep,
              COUNT(running_amt) AS orders_before_10k
          FROM (
                SELECT accounts.sales_rep_id AS rep,
                        SUM(total_amt_usd) OVER
                          (PARTITION BY accounts.sales_rep_id ORDER BY occurred_at)
                          AS running_amt
                    FROM sqlchallenge1.orders orders
                      JOIN sqlchallenge1.accounts accounts
                        ON orders.account_id = accounts.id
                  ) sub
            WHERE running_amt < 10000
            GROUP BY 1
            ORDER BY 2 DESC
        ) counted

--ADVANCED EXERCISE #5: What two-calendar-day period had the largest dollar
--amount of purchases? Enter the first day in YYYY-MM-DD format.)
--my answer: IDK. revisit!

/*
SELECT *
  FROM (
        SELECT order_date, running_amt,
              SUM(order_interval) OVER (ORDER BY order_date) AS fixed_interval
          FROM (
                SELECT occurred_at AS order_date,
                      SUM(total_amt_usd) OVER (ORDER BY occurred_at) AS running_amt,
                      occurred_at - LAG(occurred_at, 1) OVER
                        (ORDER BY occurred_at) AS order_interval,
                      EXTRACT('day' FROM occurred_at) AS order_day
                FROM sqlchallenge1.orders
              ) sub
        ) fixed
    WHERE fixed_interval < '3 days'
*/
