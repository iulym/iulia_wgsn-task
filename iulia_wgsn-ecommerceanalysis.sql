-- E-commerce Analysis SQL Script
-- Load data tables
LOAD DATA IN FILE 'product_dimensions.csv' INTO TABLE product_dimensions;
LOAD DATA IN FILE 'weekly_tracker.csv' INTO TABLE weekly_tracker;
LOAD DATA IN FILE 'social.csv' INTO TABLE social;

-- KEY E-COMMERCE METRICS & SUMMARY STATISTICS
-- Dataset Overview (Spring/Summer 2025 only: 202503-202509)
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT PC_ID) as unique_products_tracked,
  COUNT(DISTINCT STYLE) as total_styles,
  COUNT(DISTINCT WEEK_START_DATE) as weeks_in_season,
  MIN(WEEK_START_DATE) as season_start,
  MAX(WEEK_START_DATE) as season_end,
  'SS2025 (March-September 2025)' as season_definition
FROM weekly_tracker wt
JOIN product_dimensions pd ON wt.PC_ID = pd.PC_ID
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509;

-- Price Statistics (SS2025 only)
SELECT 
  ROUND(AVG(ORIGINAL_PRICE), 2) as avg_price,
  ROUND(STDDEV(ORIGINAL_PRICE), 2) as std_dev_price,
  ROUND(MIN(ORIGINAL_PRICE), 2) as min_price,
  ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ORIGINAL_PRICE), 2) as q1_price,
  ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ORIGINAL_PRICE), 2) as median_price,
  ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ORIGINAL_PRICE), 2) as q3_price,
  ROUND(MAX(ORIGINAL_PRICE), 2) as max_price
FROM weekly_tracker wt
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509;

-- YEAR-ON-YEAR COMPARISON - Spring/Summer 2024 vs Spring/Summer 2025
-- Date range: SS2024 = 202403-202409, SS2025 = 202503-202509
-- Isolating by century prefix in WEEK_START_DATE (YYYYMMDD format)

-- Create YoY comparison dataset
CREATE TEMPORARY TABLE yoy_comparison AS
SELECT 
  wt.PC_ID,
  pd.STYLE,
  CASE 
    WHEN wt.WEEK_START_DATE BETWEEN 202503 AND 202509 THEN 'SS2025'
    WHEN wt.WEEK_START_DATE BETWEEN 202403 AND 202409 THEN 'SS2024'
    ELSE 'OTHER'
  END as season_year,
  CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN = 0 THEN 1 ELSE 0 END as fpoos_flag,
  CASE 
    WHEN wt.ORIGINAL_PRICE > 0 AND wt.WEEKLY_AVERAGE_MARKDOWN_PRICE > 0 
    THEN ROUND(((wt.ORIGINAL_PRICE - wt.WEEKLY_AVERAGE_MARKDOWN_PRICE) / wt.ORIGINAL_PRICE * 100), 2)
    ELSE 0 
  END as markdown_depth_pct,
  CASE WHEN wt.PRODUCT_NEW_IN > 0 THEN 1 ELSE 0 END as new_in_flag,
  wt.ORIGINAL_PRICE
FROM weekly_tracker wt
JOIN product_dimensions pd ON wt.PC_ID = pd.PC_ID
WHERE (wt.WEEK_START_DATE BETWEEN 202503 AND 202509)
   OR (wt.WEEK_START_DATE BETWEEN 202403 AND 202409);

-- Year-on-Year Comparison by Style (SS2024 vs SS2025)
SELECT 
  STYLE,
  MAX(CASE WHEN season_year = 'SS2024' THEN unique_products END) as products_ss2024,
  MAX(CASE WHEN season_year = 'SS2025' THEN unique_products END) as products_ss2025,
  MAX(CASE WHEN season_year = 'SS2024' THEN fpoos_pct END) as fpoos_pct_ss2024,
  MAX(CASE WHEN season_year = 'SS2025' THEN fpoos_pct END) as fpoos_pct_ss2025,
  ROUND(MAX(CASE WHEN season_year = 'SS2025' THEN fpoos_pct END) - MAX(CASE WHEN season_year = 'SS2024' THEN fpoos_pct END), 2) as fpoos_pct_change,
  MAX(CASE WHEN season_year = 'SS2024' THEN avg_markdown_pct END) as markdown_pct_ss2024,
  MAX(CASE WHEN season_year = 'SS2025' THEN avg_markdown_pct END) as markdown_pct_ss2025,
  ROUND(MAX(CASE WHEN season_year = 'SS2025' THEN avg_markdown_pct END) - MAX(CASE WHEN season_year = 'SS2024' THEN avg_markdown_pct END), 2) as markdown_pct_change,
  MAX(CASE WHEN season_year = 'SS2024' THEN new_in_pct END) as new_in_pct_ss2024,
  MAX(CASE WHEN season_year = 'SS2025' THEN new_in_pct END) as new_in_pct_ss2025,
  ROUND(MAX(CASE WHEN season_year = 'SS2025' THEN new_in_pct END) - MAX(CASE WHEN season_year = 'SS2024' THEN new_in_pct END), 2) as new_in_pct_change,
  MAX(CASE WHEN season_year = 'SS2024' THEN avg_price END) as avg_price_ss2024,
  MAX(CASE WHEN season_year = 'SS2025' THEN avg_price END) as avg_price_ss2025,
  ROUND(MAX(CASE WHEN season_year = 'SS2025' THEN avg_price END) - MAX(CASE WHEN season_year = 'SS2024' THEN avg_price END), 2) as price_change,
  CASE 
    WHEN MAX(CASE WHEN season_year = 'SS2025' THEN fpoos_pct END) < MAX(CASE WHEN season_year = 'SS2024' THEN fpoos_pct END) AND
         MAX(CASE WHEN season_year = 'SS2025' THEN avg_markdown_pct END) < MAX(CASE WHEN season_year = 'SS2024' THEN avg_markdown_pct END) THEN 'IMPROVED'
    WHEN MAX(CASE WHEN season_year = 'SS2025' THEN fpoos_pct END) > MAX(CASE WHEN season_year = 'SS2024' THEN fpoos_pct END) AND
         MAX(CASE WHEN season_year = 'SS2025' THEN avg_markdown_pct END) > MAX(CASE WHEN season_year = 'SS2024' THEN avg_markdown_pct END) THEN 'DECLINED'
    ELSE 'MIXED'
  END as yoy_trend
FROM (
  SELECT 
    season_year,
    STYLE,
    COUNT(DISTINCT PC_ID) as unique_products,
    ROUND(COUNT(CASE WHEN fpoos_flag = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as fpoos_pct,
    ROUND(AVG(CASE WHEN markdown_depth_pct > 0 THEN markdown_depth_pct ELSE NULL END), 2) as avg_markdown_pct,
    ROUND(COUNT(CASE WHEN new_in_flag = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as new_in_pct,
    ROUND(AVG(ORIGINAL_PRICE), 2) as avg_price
  FROM yoy_comparison
  WHERE season_year IN ('SS2024', 'SS2025')
  GROUP BY season_year, STYLE
) AS season_data
GROUP BY STYLE
ORDER BY STYLE;

-- Overall E-Commerce Health Metrics (SS2025 only)
SELECT 
  ROUND(COUNT(CASE WHEN PRODUCT_OUT_OF_STOCK > 0 AND PRODUCT_MARKDOWN = 0 THEN 1 END) * 100.0 / COUNT(*), 2) as overall_fpoos_pct,
  ROUND(COUNT(CASE WHEN PRODUCT_MARKDOWN > 0 THEN 1 END) * 100.0 / COUNT(*), 2) as markdown_active_pct,
  ROUND(COUNT(CASE WHEN PRODUCT_NEW_IN > 0 THEN 1 END) * 100.0 / COUNT(*), 2) as overall_new_in_pct,
  SUM(PRODUCT_INSTOCK) as total_units_in_stock,
  SUM(PRODUCT_OUT_OF_STOCK) as total_units_oos
FROM weekly_tracker wt
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509;

-- CALCULATE KEY PERFORMANCE METRICS

-- Define and calculate FPOOS%, Markdown Depth%, and New In% at product-week level
-- Analyzing Spring/Summer 2025 (202503-202509)

-- Temporary table: Weekly metrics for each product - SS2025 ONLY
CREATE TEMPORARY TABLE weekly_metrics AS
SELECT 
  wt.WEEK_START_DATE,
  wt.PC_ID,
  pd.STYLE,
  pd.RETAILER_NAME,
  pd.RETAILER_SEGMENT,
  wt.ORIGINAL_PRICE,
  wt.PRODUCT_INSTOCK,
  wt.PRODUCT_OUT_OF_STOCK,
  wt.PRODUCT_NEW_IN,
  wt.PRODUCT_MARKDOWN,
  wt.WEEKLY_AVERAGE_PRICE,
  wt.WEEKLY_AVERAGE_MARKDOWN_PRICE,
  -- Metric 1: FPOOS (Full Price Out Of Stock) - OOS without markdown
  CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN = 0 THEN 1 ELSE 0 END as fpoos_flag,
  -- Metric 2: Markdown Depth % = (Original_Price - Weekly_Avg_Markdown_Price) / Original_Price * 100
  CASE 
    WHEN wt.ORIGINAL_PRICE > 0 AND wt.WEEKLY_AVERAGE_MARKDOWN_PRICE > 0 
    THEN ROUND(((wt.ORIGINAL_PRICE - wt.WEEKLY_AVERAGE_MARKDOWN_PRICE) / wt.ORIGINAL_PRICE * 100), 2)
    ELSE 0 
  END as markdown_depth_pct,
  -- Metric 3: New In indicator
  CASE WHEN (wt.PRODUCT_NEW_IN > 0) THEN 1 ELSE 0 END as new_in_flag
FROM weekly_tracker wt
JOIN product_dimensions pd ON wt.PC_ID = pd.PC_ID
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509;

-- Weekly summary by style - SS2025 ONLY
CREATE TEMPORARY TABLE style_weekly_summary AS
SELECT 
  WEEK_START_DATE,
  STYLE,
  COUNT(DISTINCT PC_ID) as style_count,
  AVG(ORIGINAL_PRICE) as avg_original_price,
  SUM(PRODUCT_INSTOCK) as total_instock,
  SUM(PRODUCT_OUT_OF_STOCK) as total_oos,
  SUM(PRODUCT_NEW_IN) as total_new_in,
  SUM(PRODUCT_MARKDOWN) as total_markdown,
  ROUND(COUNT(CASE WHEN fpoos_flag = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as fpoos_pct,
  ROUND(AVG(CASE WHEN markdown_depth_pct > 0 THEN markdown_depth_pct ELSE NULL END), 2) as avg_markdown_depth_pct,
  ROUND(COUNT(CASE WHEN new_in_flag = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as new_in_pct
FROM weekly_metrics
GROUP BY WEEK_START_DATE, STYLE;

-- Seasonal summary by style - SS2025 ONLY (entire Spring/Summer 2025 season)
CREATE TEMPORARY TABLE style_seasonal_summary AS
SELECT 
  STYLE,
  COUNT(DISTINCT PC_ID) as unique_products,
  COUNT(DISTINCT WEEK_START_DATE) as weeks_in_season,
  ROUND(AVG(ORIGINAL_PRICE), 2) as avg_original_price,
  SUM(PRODUCT_INSTOCK) as total_instock,
  SUM(PRODUCT_OUT_OF_STOCK) as total_oos,
  ROUND(COUNT(CASE WHEN fpoos_flag = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as fpoos_pct,
  ROUND(AVG(CASE WHEN markdown_depth_pct > 0 THEN markdown_depth_pct ELSE NULL END), 2) as avg_markdown_depth_pct,
  ROUND(COUNT(CASE WHEN new_in_flag = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as new_in_pct
FROM weekly_metrics
GROUP BY STYLE;


-- STYLE PERFORMANCE ANALYSIS - BEST vs WORST PERFORMERS

-- Complete Style Scorecard - Ranked Performance
SELECT 
  ROW_NUMBER() OVER (ORDER BY fpoos_pct ASC, avg_markdown_depth_pct ASC, new_in_pct DESC) as performance_rank,
  STYLE,
  unique_products,
  ROUND(avg_original_price, 2) as avg_price,
  fpoos_pct,
  avg_markdown_depth_pct,
  new_in_pct,
  CASE 
    WHEN fpoos_pct < 20 AND avg_markdown_depth_pct < 15 AND new_in_pct > 20 THEN 'TOP PERFORMER'
    WHEN fpoos_pct < 30 AND avg_markdown_depth_pct < 20 THEN 'STRONG PERFORMER'
    WHEN fpoos_pct > 50 OR avg_markdown_depth_pct > 35 OR new_in_pct < 5 THEN 'UNDERPERFORMER'
    ELSE 'AVERAGE PERFORMER'
  END as performance_rating
FROM style_seasonal_summary
ORDER BY performance_rank;

-- TOP PERFORMERS - Best performing styles
-- Criteria: Low FPOOS, low markdown pressure, healthy assortment refresh
SELECT 
  'TOP PERFORMERS' as category,
  STYLE,
  unique_products,
  ROUND(avg_original_price, 2) as avg_price,
  fpoos_pct,
  avg_markdown_depth_pct,
  new_in_pct,
  'Recommendation: MAINTAIN CURRENT STRATEGY' as action
FROM style_seasonal_summary
WHERE fpoos_pct < 20 AND avg_markdown_depth_pct < 15 AND new_in_pct > 20
ORDER BY fpoos_pct ASC, avg_markdown_depth_pct ASC;

-- UNDERPERFORMERS - Worst performing styles
-- Criteria: High FPOOS, high markdown pressure, or low assortment refresh
SELECT 
  'UNDERPERFORMERS' as category,
  STYLE,
  unique_products,
  ROUND(avg_original_price, 2) as avg_price,
  fpoos_pct,
  avg_markdown_depth_pct,
  new_in_pct,
  CASE 
    WHEN fpoos_pct > 50 THEN 'ACTION NEEDED: High stockout rate - review demand forecasting'
    WHEN avg_markdown_depth_pct > 35 THEN 'ACTION NEEDED: High markdown pressure - review pricing/positioning'
    WHEN new_in_pct < 5 THEN 'ACTION NEEDED: Stale assortment - increase new product launches'
    ELSE 'ACTION NEEDED: Review overall performance'
  END as action_required
FROM style_seasonal_summary
WHERE fpoos_pct > 50 OR avg_markdown_depth_pct > 35 OR new_in_pct < 5
ORDER BY fpoos_pct DESC, avg_markdown_depth_pct DESC;

-- DETAILED FPOOS ANALYSIS - Full Price Out Of Stock Identification

-- Key Insight: Strong demand indicator when product sells through before discounting

-- Products that experienced FPOOS - Detail View
SELECT 
  wt.WEEK_START_DATE,
  pd.STYLE,
  pd.RETAILER_NAME,
  wt.PC_ID,
  wt.ORIGINAL_PRICE,
  wt.PRODUCT_OUT_OF_STOCK as units_oos,
  wt.PRODUCT_INSTOCK as units_instock,
  wt.PRODUCT_MARKDOWN as markdown_flag,
  wt.WEEKLY_AVERAGE_PRICE,
  wt.WEEKLY_AVERAGE_MARKDOWN_PRICE,
  'FPOOS - Sold Out at Full Price' as fpoos_indicator
FROM weekly_tracker wt
JOIN product_dimensions pd ON wt.PC_ID = pd.PC_ID
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509
  AND wt.PRODUCT_OUT_OF_STOCK > 0
  AND wt.PRODUCT_MARKDOWN = 0
ORDER BY wt.WEEK_START_DATE DESC, pd.STYLE;

-- FPOOS Summary by Style (SS2025)
SELECT 
  pd.STYLE,
  COUNT(DISTINCT wt.PC_ID) as products_with_fpoos,
  COUNT(*) as fpoos_instances,
  SUM(wt.PRODUCT_OUT_OF_STOCK) as total_units_fpoos,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM weekly_tracker WHERE WEEK_START_DATE BETWEEN 202503 AND 202509 AND PRODUCT_OUT_OF_STOCK > 0), 2) as fpoos_share_of_total,
  ROUND(AVG(wt.ORIGINAL_PRICE), 2) as avg_full_price,
  'POSITIVE SIGNAL: High demand at full price' as interpretation
FROM weekly_tracker wt
JOIN product_dimensions pd ON wt.PC_ID = pd.PC_ID
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509
  AND wt.PRODUCT_OUT_OF_STOCK > 0
  AND wt.PRODUCT_MARKDOWN = 0
GROUP BY pd.STYLE
ORDER BY fpoos_instances DESC;

-- FPOOS vs Total Out-of-Stock - Markdown Strategy Comparison
SELECT 
  pd.STYLE,
  SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN = 0 THEN 1 ELSE 0 END) as fpoos_instances,
  SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN > 0 THEN 1 ELSE 0 END) as oos_with_markdown_instances,
  SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 THEN 1 ELSE 0 END) as total_oos_instances,
  ROUND(SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN = 0 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 THEN 1 ELSE 0 END), 0), 2) as fpoos_pct_of_all_oos,
  CASE 
    WHEN SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN = 0 THEN 1 ELSE 0 END) > SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN > 0 THEN 1 ELSE 0 END) THEN 'Strong natural demand'
    WHEN SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN = 0 THEN 1 ELSE 0 END) < SUM(CASE WHEN wt.PRODUCT_OUT_OF_STOCK > 0 AND wt.PRODUCT_MARKDOWN > 0 THEN 1 ELSE 0 END) THEN 'Markdown required to clear'
    ELSE 'Balanced approach'
  END as demand_assessment
FROM weekly_tracker wt
JOIN product_dimensions pd ON wt.PC_ID = pd.PC_ID
WHERE wt.WEEK_START_DATE BETWEEN 202503 AND 202509
  AND wt.PRODUCT_OUT_OF_STOCK > 0
GROUP BY pd.STYLE
ORDER BY fpoos_pct_of_all_oos DESC;

-- MARKDOWN DEPTH EVOLUTION ACROSS THE SEASON

-- Question: How does markdown depth evolve across the season?
-- Which weeks are above the seasonal average?

-- CALCULATION Seasonal average markdown depth
CREATE TEMPORARY TABLE markdown_seasonal_avg AS
SELECT 
  ROUND(AVG(markdown_depth_pct), 2) as seasonal_avg_markdown_depth,
  MIN(markdown_depth_pct) as min_markdown_depth,
  MAX(markdown_depth_pct) as max_markdown_depth,
  ROUND(STDDEV(markdown_depth_pct), 2) as std_dev_markdown
FROM weekly_metrics
WHERE markdown_depth_pct > 0;

-- Weekly markdown depth trend with seasonal comparison
SELECT 
  s.WEEK_START_DATE,
  s.STYLE,
  s.avg_markdown_depth_pct,
  m.seasonal_avg_markdown_depth,
  ROUND(s.avg_markdown_depth_pct - m.seasonal_avg_markdown_depth, 2) as diff_from_seasonal_avg,
  ROUND((s.avg_markdown_depth_pct - m.seasonal_avg_markdown_depth) / NULLIF(m.seasonal_avg_markdown_depth, 0) * 100, 2) as pct_diff_from_avg,
  CASE 
    WHEN s.avg_markdown_depth_pct > m.seasonal_avg_markdown_depth * 1.2 THEN 'SIGNIFICANTLY ABOVE (>20%)'
    WHEN s.avg_markdown_depth_pct > m.seasonal_avg_markdown_depth THEN 'ABOVE AVERAGE'
    ELSE 'BELOW AVERAGE'
  END as markdown_alert_flag,
  s.fpoos_pct,
  s.new_in_pct
FROM style_weekly_summary s
CROSS JOIN markdown_seasonal_avg m
ORDER BY s.WEEK_START_DATE ASC, s.STYLE ASC;

-- FLAGGED WEEKS - Markdown depth significantly above seasonal average
-- These weeks represent promotional intensity spikes requiring investigation
SELECT 
  s.WEEK_START_DATE,
  s.STYLE,
  s.avg_markdown_depth_pct as weekly_markdown_depth,
  m.seasonal_avg_markdown_depth,
  ROUND((s.avg_markdown_depth_pct - m.seasonal_avg_markdown_depth) / NULLIF(m.seasonal_avg_markdown_depth, 0) * 100, 2) as pct_above_seasonal,
  s.fpoos_pct,
  s.new_in_pct,
  s.style_count as products_tracked,
  'INVESTIGATE' as action_flag
FROM style_weekly_summary s
CROSS JOIN markdown_seasonal_avg m
WHERE s.avg_markdown_depth_pct > m.seasonal_avg_markdown_depth * 1.2 -- 20% above average
ORDER BY s.WEEK_START_DATE DESC, s.pct_above_seasonal DESC;

-- Summary of flagged weeks (grouped by week)
SELECT 
  s.WEEK_START_DATE,
  COUNT(DISTINCT s.STYLE) as styles_flagged,
  ROUND(AVG(s.avg_markdown_depth_pct), 2) as avg_markdown_that_week,
  m.seasonal_avg_markdown_depth,
  ROUND((AVG(s.avg_markdown_depth_pct) - m.seasonal_avg_markdown_depth) / NULLIF(m.seasonal_avg_markdown_depth, 0) * 100, 2) as week_avg_pct_above_seasonal,
  COUNT(DISTINCT s.STYLE) as high_promo_styles
FROM style_weekly_summary s
CROSS JOIN markdown_seasonal_avg m
WHERE s.avg_markdown_depth_pct > m.seasonal_avg_markdown_depth * 1.2
GROUP BY s.WEEK_START_DATE, m.seasonal_avg_markdown_depth
ORDER BY s.WEEK_START_DATE DESC;


-- EXECUTIVE SUMMARY & KEY INSIGHTS

-- Style Performance Summary Scorecard. Comprehensive view of all styles ranked by performance
SELECT 
  STYLE,
  unique_products,
  ROUND(avg_original_price, 2) as avg_price,
  ROUND(fpoos_pct, 2) as fpoos_pct,
  ROUND(avg_markdown_depth_pct, 2) as avg_markdown_depth_pct,
  ROUND(new_in_pct, 2) as new_in_pct,
  CASE 
    WHEN fpoos_pct < 20 AND avg_markdown_depth_pct < 15 AND new_in_pct > 20 THEN 'TOP PERFORMER'
    WHEN fpoos_pct < 30 AND avg_markdown_depth_pct < 20 THEN 'STRONG'
    WHEN fpoos_pct > 50 OR avg_markdown_depth_pct > 35 THEN 'UNDERPERFORMER'
    ELSE 'AVERAGE'
  END as performance_rating
FROM style_seasonal_summary
ORDER BY fpoos_pct ASC, avg_markdown_depth_pct ASC, new_in_pct DESC;

-- Markdown Season Overview
SELECT 
  'Markdown Depth Overview' as metric_type,
  seasonal_avg_markdown_depth,
  min_markdown_depth,
  max_markdown_depth,
  std_dev_markdown,
  'Key Insights: Review weeks with >20% above-average markdown for strategic opportunities' as note
FROM markdown_seasonal_avg;

