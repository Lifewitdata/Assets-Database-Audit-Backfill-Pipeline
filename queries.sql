-- master fund table
-- one row per fund
CREATE TABLE IF NOT EXISTS funds (
    fund_id          INT             AUTO_INCREMENT PRIMARY KEY,
    fund_name        VARCHAR(200)    NOT NULL,
    asset_class      VARCHAR(50)     NOT NULL,   -- e.g. Private Equity, Venture Capital
    geography        VARCHAR(50)     NOT NULL,   -- e.g. North America, Europe
    fund_size_usd_m  DECIMAL(12, 2)  NULL,       -- fund size in millions USD, can be missing
    vintage_year     INT             NULL,        -- year fund was launched
    status           VARCHAR(20)     NOT NULL DEFAULT 'Active',  -- Active / Closed
    date_added       DATE            NOT NULL DEFAULT (CURRENT_DATE)
);

-- deals table
-- one row per investment a fund made
CREATE TABLE IF NOT EXISTS deals (
    deal_id          INT             AUTO_INCREMENT PRIMARY KEY,
    fund_id          INT             NOT NULL,
    company_name     VARCHAR(200)    NOT NULL,
    deal_type        VARCHAR(50)     NOT NULL,   -- e.g. Buyout, Growth, Venture
    deal_size_usd_m  DECIMAL(12, 2)  NULL,       -- deal size in millions, can be missing
    deal_date        DATE            NULL,
    sector           VARCHAR(100)    NULL,        -- e.g. Technology, Healthcare
    country          VARCHAR(100)    NULL,

    -- link back to funds table
    FOREIGN KEY (fund_id) REFERENCES funds(fund_id)
);

-- valuations table
-- quarterly NAV (net asset value) per fund
CREATE TABLE IF NOT EXISTS valuations (
    valuation_id     INT             AUTO_INCREMENT PRIMARY KEY,
    fund_id          INT             NOT NULL,
    quarter          VARCHAR(10)     NOT NULL,   -- e.g. Q1-2024
    nav_usd_m        DECIMAL(12, 2)  NULL,       -- NAV in millions, NULL = missing data
    reported_date    DATE            NULL,

    FOREIGN KEY (fund_id) REFERENCES funds(fund_id)
);


-- insert 10 sample funds across different asset classes
INSERT INTO funds (fund_name, asset_class, geography, fund_size_usd_m, vintage_year, status)
VALUES
    ('Blackstone Capital Partners IX',   'Private Equity',   'North America',  26000.00, 2023, 'Active'),
    ('Apollo Investment Fund XI',        'Private Equity',   'North America',  24500.00, 2022, 'Active'),
    ('Sequoia Capital Global Fund',      'Venture Capital',  'North America',   8500.00, 2023, 'Active'),
    ('KKR European Fund VI',             'Private Equity',   'Europe',         15000.00, 2022, 'Active'),
    ('Carlyle Asia Partners V',          'Private Equity',   'Asia Pacific',    6500.00, 2021, 'Active'),
    ('Tiger Global Private Fund XV',     'Venture Capital',  'North America',   5000.00, 2022, 'Active'),
    ('Partners Group Direct Equity VII', 'Private Equity',   'Europe',         12000.00, 2021, 'Active'),
    ('GreenSpring Associates Fund',      'Venture Capital',  'North America',      NULL, 2023, 'Active'),  -- fund size missing
    ('Warburg Pincus Global Growth',     'Growth Equity',    'Global',          4750.00, 2020, 'Closed'),
    ('TPG Rise Climate Fund',            'Infrastructure',   'Global',           7000.00, 2021, 'Active');


    -- insert sample deals linked to funds
INSERT INTO deals (fund_id, company_name, deal_type, deal_size_usd_m, deal_date, sector, country)
VALUES
    (1, 'Hilton Hotels',         'Buyout',  26000.00, '2024-01-15', 'Hospitality',  'USA'),
    (1, 'ServiceNow',            'Growth',   4500.00, '2024-03-20', 'Technology',   'USA'),
    (2, 'ADT Security',          'Buyout',   6900.00, '2024-02-10', 'Security',     'USA'),
    (2, 'Rexnord Corporation',   'Buyout',      NULL, '2024-04-05', 'Industrials',  'USA'),  -- deal size missing
    (3, 'Stripe Inc',            'Venture',  6500.00, '2024-01-28', 'Fintech',      'USA'),
    (3, 'Databricks',            'Venture',  4300.00, '2024-05-12', 'Technology',   'USA'),
    (4, 'Springer Nature',       'Buyout',   5300.00, '2024-02-22', 'Media',        'Germany'),
    (4, 'TeamViewer AG',         'Growth',      NULL, NULL,         'Technology',   'Germany'), -- date and size missing
    (5, 'Manbang Group',         'Growth',   1900.00, '2024-03-08', 'Logistics',    'China'),
    (6, 'Canva',                 'Venture',  3260.00, '2024-04-19', 'Technology',   'Australia'),
    (7, 'Visma Group',           'Buyout',   9000.00, '2024-01-30', 'Technology',   'Norway'),
    (10,'CleanTech Solutions',   'Growth',    850.00, '2024-06-01', 'Clean Energy', 'USA');

    -- quarterly valuations for each fund
-- some deliberately left NULL to simulate missing data we will catch in Step 2
INSERT INTO valuations (fund_id, quarter, nav_usd_m, reported_date)
VALUES
    (1, 'Q1-2024', 27500.00, '2024-03-31'),
    (1, 'Q2-2024', 28100.00, '2024-06-30'),
    (2, 'Q1-2024', 25200.00, '2024-03-31'),
    (2, 'Q2-2024',     NULL, NULL),           -- missing valuation
    (3, 'Q1-2024',  8900.00, '2024-03-31'),
    (3, 'Q2-2024',  9100.00, '2024-06-30'),
    (4, 'Q1-2024', 15400.00, '2024-03-31'),
    (4, 'Q2-2024',     NULL, NULL),           -- missing valuation
    (5, 'Q1-2024',  6700.00, '2024-03-31'),
    (5, 'Q2-2024',  6850.00, '2024-06-30'),
    (6, 'Q1-2024',  5100.00, '2024-03-31'),
    (7, 'Q1-2024', 12300.00, '2024-03-31'),
    (7, 'Q2-2024', 12750.00, '2024-06-30'),
    (9, 'Q1-2024',  4900.00, '2024-03-31'),
    (10,'Q1-2024',  7200.00, '2024-03-31');
    -- funds 6, 8, 10 have no Q2 valuation — gap we catch in Step 2


    -- quick check: how many rows in each table?
SELECT 'funds'      AS table_name, COUNT(*) AS row_count FROM funds
UNION ALL
SELECT 'deals'      AS table_name, COUNT(*) AS row_count FROM deals
UNION ALL
SELECT 'valuations' AS table_name, COUNT(*) AS row_count FROM valuations;

-- which funds have NULL nav values in their valuations?
-- these are records that need to be backfilled

SELECT
    f.fund_id,
    f.fund_name,
    f.asset_class,
    v.quarter,
    v.nav_usd_m,
    v.reported_date
FROM funds f
JOIN valuations v
    ON f.fund_id = v.fund_id
WHERE v.nav_usd_m IS NULL
   OR v.reported_date IS NULL
ORDER BY f.fund_name, v.quarter;

-- funds that exist in the funds table
-- but have zero rows in valuations
-- these are completely missing from our coverage

SELECT
    f.fund_id,
    f.fund_name,
    f.asset_class,
    f.geography,
    f.vintage_year,
    f.status
FROM funds f
LEFT JOIN valuations v
    ON f.fund_id = v.fund_id
WHERE v.fund_id IS NULL
ORDER BY f.asset_class;


-- which active funds do NOT have a Q2-2024 valuation?
-- useful for targeted backfill campaigns

SELECT
    f.fund_id,
    f.fund_name,
    f.asset_class,
    f.geography
FROM funds f
WHERE f.status = 'Active'
  AND f.fund_id NOT IN (
        SELECT fund_id
        FROM   valuations
        WHERE  quarter = 'Q2-2024'
          AND  nav_usd_m IS NOT NULL
  )
ORDER BY f.asset_class, f.fund_name;

-- deals where size, date, or sector is missing
-- use CASE to label exactly which fields are problematic

SELECT
    d.deal_id,
    d.company_name,
    f.fund_name,
    d.deal_type,
    d.deal_date,
    d.deal_size_usd_m,
    d.sector,

    -- label each missing field clearly
    CASE WHEN d.deal_size_usd_m IS NULL THEN 'YES' ELSE 'NO' END AS size_missing,
    CASE WHEN d.deal_date        IS NULL THEN 'YES' ELSE 'NO' END AS date_missing,
    CASE WHEN d.sector           IS NULL THEN 'YES' ELSE 'NO' END AS sector_missing

FROM deals d
JOIN funds f
    ON d.fund_id = f.fund_id
WHERE d.deal_size_usd_m IS NULL
   OR d.deal_date        IS NULL
   OR d.sector           IS NULL
ORDER BY d.deal_id;

-- use a CTE to build a clean coverage summary
-- shows total funds, how many have valuations, and the gap

WITH fund_coverage AS (

    -- for each fund, check if it has at least one valuation
    SELECT
        f.fund_id,
        f.asset_class,
        f.geography,
        COUNT(v.valuation_id)               AS valuation_count,
        SUM(CASE WHEN v.nav_usd_m IS NULL
                 THEN 1 ELSE 0 END)         AS missing_nav_count
    FROM funds f
    LEFT JOIN valuations v
        ON f.fund_id = v.fund_id
    GROUP BY f.fund_id, f.asset_class, f.geography

)

-- now summarise by asset class
SELECT
    asset_class,
    COUNT(*)                                        AS total_funds,
    SUM(CASE WHEN valuation_count  > 0
             THEN 1 ELSE 0 END)                     AS funds_with_valuations,
    SUM(CASE WHEN valuation_count  = 0
             THEN 1 ELSE 0 END)                     AS funds_no_valuations,
    SUM(missing_nav_count)                          AS total_missing_navs

FROM fund_coverage
GROUP BY asset_class
ORDER BY total_funds DESC;

-- funds whose most recent valuation is older than 90 days
-- these are stale and need to be chased

SELECT
    f.fund_id,
    f.fund_name,
    f.asset_class,
    MAX(v.reported_date)                        AS last_reported,
    DATEDIFF(CURRENT_DATE, MAX(v.reported_date)) AS days_since_update

FROM funds f
JOIN valuations v
    ON f.fund_id = v.fund_id
WHERE v.reported_date IS NOT NULL
GROUP BY f.fund_id, f.fund_name, f.asset_class
HAVING DATEDIFF(CURRENT_DATE, MAX(v.reported_date)) > 90
ORDER BY days_since_update DESC;

SELECT
    fund_id,
    fund_name,
    ROW_NUMBER() OVER (
        PARTITION BY asset_class
        ORDER BY vintage_year
    ) AS rn
FROM funds;

-- assign a row number to each valuation per fund
-- ordered by quarter so we can track the sequence

SELECT
    f.fund_name,
    f.asset_class,
    v.quarter,
    v.nav_usd_m,

    ROW_NUMBER() OVER (
        PARTITION BY v.fund_id      -- restart count for each fund
        ORDER BY v.quarter          -- oldest quarter = row 1
    ) AS quarter_number

FROM valuations v
JOIN funds f
    ON v.fund_id = f.fund_id
WHERE v.nav_usd_m IS NOT NULL
ORDER BY f.fund_name, v.quarter;

-- rank funds by their latest NAV within their asset class
-- ties get the same rank (unlike ROW_NUMBER)

WITH latest_nav AS (

    -- get only the most recent valuation per fund
    SELECT
        fund_id,
        nav_usd_m,
        quarter,
        ROW_NUMBER() OVER (
            PARTITION BY fund_id
            ORDER BY quarter DESC    -- most recent first
        ) AS rn
    FROM valuations
    WHERE nav_usd_m IS NOT NULL

)

SELECT
    f.fund_name,
    f.asset_class,
    f.geography,
    ln.quarter        AS latest_quarter,
    ln.nav_usd_m      AS latest_nav_usd_m,

    RANK() OVER (
        PARTITION BY f.asset_class   -- rank within each asset class
        ORDER BY ln.nav_usd_m DESC   -- largest NAV = rank 1
    ) AS rank_in_class

FROM latest_nav ln
JOIN funds f
    ON ln.fund_id = f.fund_id
WHERE ln.rn = 1                      -- keep only most recent row per fund
ORDER BY f.asset_class, rank_in_class;

-- compare each fund's NAV to the previous quarter
-- LAG looks back one row within the same partition

SELECT
    f.fund_name,
    f.asset_class,
    v.quarter,
    v.nav_usd_m                             AS current_nav,

    -- pull the previous quarter's NAV for same fund
    LAG(v.nav_usd_m) OVER (
        PARTITION BY v.fund_id
        ORDER BY v.quarter
    )                                        AS previous_nav,

    -- calculate the change in value
    v.nav_usd_m - LAG(v.nav_usd_m) OVER (
        PARTITION BY v.fund_id
        ORDER BY v.quarter
    )                                        AS nav_change_usd_m,

    -- calculate percentage change
    ROUND(
        (v.nav_usd_m - LAG(v.nav_usd_m) OVER (
            PARTITION BY v.fund_id
            ORDER BY v.quarter
        )) / LAG(v.nav_usd_m) OVER (
            PARTITION BY v.fund_id
            ORDER BY v.quarter
        ) * 100
    , 2)                                     AS nav_change_pct

FROM valuations v
JOIN funds f
    ON v.fund_id = f.fund_id
WHERE v.nav_usd_m IS NOT NULL
ORDER BY f.fund_name, v.quarter;

-- cumulative NAV as we add each fund within an asset class
-- shows how much of the total each fund contributes

WITH latest_nav AS (

    SELECT
        fund_id,
        nav_usd_m,
        ROW_NUMBER() OVER (
            PARTITION BY fund_id
            ORDER BY quarter DESC
        ) AS rn
    FROM valuations
    WHERE nav_usd_m IS NOT NULL

)

SELECT
    f.asset_class,
    f.fund_name,
    ln.nav_usd_m,

    -- running total within asset class ordered by fund size
    SUM(ln.nav_usd_m) OVER (
        PARTITION BY f.asset_class
        ORDER BY ln.nav_usd_m DESC
    )                               AS running_total_usd_m,

    -- each fund's share of the total in its class
    ROUND(
        ln.nav_usd_m /
        SUM(ln.nav_usd_m) OVER (
            PARTITION BY f.asset_class
        ) * 100
    , 1)                            AS pct_of_class

FROM latest_nav ln
JOIN funds f
    ON ln.fund_id = f.fund_id
WHERE ln.rn = 1
ORDER BY f.asset_class, ln.nav_usd_m DESC;

