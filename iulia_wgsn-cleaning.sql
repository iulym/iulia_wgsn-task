-- This is only for cleaning purposes only to ensure the data is ready for analysis.
-- Load data into tables

LOAD LOCAL DATA INFILE '/mnt/data/product_dimensions.csvproduct_dimensions.csv' INTO TABLE product_dimensions;
LOAD LOCAL DATA INFILE '/mnt/data/weekly_tracker.csv' INTO TABLE weekly_tracker;
LOAD LOCAL DATA INFILE '/mnt/data/social.csv' INTO TABLE social;

-- Load data into tables
SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'local_infile';

-- Remove rows where Division != 'Womens', Department != 'Apparel', Category != 'Jeans'
DELETE FROM product_dimensions
WHERE Division != 'Womens'
  OR Department != 'Apparel'
  OR Category != 'Jeans';

-- Remove duplicate PC_IDs in product_dimensions (keep first occurrence)
DELETE FROM product_dimensions
WHERE PC_ID IN (
  SELECT PC_ID
  FROM (
    SELECT PC_ID, COUNT(*) as dup_count
    FROM product_dimensions
    WHERE PC_ID IS NOT NULL AND PC_ID != ''
    GROUP BY PC_ID
    HAVING COUNT(*) > 1
  ) AS duplicates
);

-- Remove duplicate PC_IDs in weekly_tracker (keep first occurrence)
DELETE FROM weekly_tracker
WHERE PC_ID IN (
  SELECT PC_ID
  FROM (
    SELECT PC_ID, COUNT(*) as dup_count
    FROM weekly_tracker
    WHERE PC_ID IS NOT NULL AND PC_ID != ''
    GROUP BY PC_ID
    HAVING COUNT(*) > 1
  ) AS duplicates
);

-- Remove NULL or empty PC_IDs from both tables
DELETE FROM product_dimensions WHERE PC_ID IS NULL OR PC_ID = '';
DELETE FROM weekly_tracker WHERE PC_ID IS NULL OR PC_ID = '';

-- Ensure PC_IDs exist in both tables (remove mismatches)
DELETE pd
FROM product_dimensions pd
LEFT JOIN weekly_tracker wt
  ON pd.PC_ID = wt.PC_ID
WHERE wt.PC_ID IS NULL;

DELETE wt
FROM weekly_tracker wt
LEFT JOIN product_dimensions pd
  ON wt.PC_ID = pd.PC_ID
WHERE pd.PC_ID IS NULL;

-- Remove invalid prices (< 0 or > 1000)
DELETE FROM weekly_tracker
WHERE ORIGINAL_PRICE < 0 OR ORIGINAL_PRICE > 1000;

-- Post-cleaning data quality summary
SELECT 
  'product_dimensions' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT PC_ID) as unique_products
FROM product_dimensions
UNION ALL
SELECT 
  'weekly_tracker' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT PC_ID) as unique_products
FROM weekly_tracker;
