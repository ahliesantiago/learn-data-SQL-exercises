--https://mode.com/sql-challenge/
--Using these 4 tables in the Mode Public Warehouse:
--sqlchallenge1.accounts, sqlchallenge1.sales_reps, sqlchallenge1.orders, sqlchallenge1.region

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
              WHERE orders.occurred_at BETWEEN '2016-09-01' AND '2016-09-30'
              GROUP BY 2, 1
          ) sub
      ON reps.id = sub.rep
  WHERE reps.name IN ('Tia Amato', 'Delilah Krum', 'Soraya Fulton')
  GROUP BY 1 --alt is no grouping and sum aggr, Tia is still the answer (?)
  ORDER BY 2 DESC

--INTERMEDIATE EXERCISE #3: 
--INTERMEDIATE EXERCISE #4: 


