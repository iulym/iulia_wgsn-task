-- Sustainability Trend Over Time

-- Filter for Sustainability Keywords (Social)
SELECT *
FROM social
WHERE LOWER(content) LIKE '%sustainable%'
	 OR LOWER(content) LIKE '%sustainably%'
	 OR LOWER(content) LIKE '%sustainability%'
	 OR LOWER(content) LIKE '%recycled%'
	 OR LOWER(content) LIKE '%organic%'
	 OR LOWER(content) LIKE '%upcycled%'
	 OR LOWER(content) LIKE '%upcycling%';

-- Filter for Sustainability Keywords (E-commerce)
SELECT *
FROM product_dimensions
WHERE LOWER(description) LIKE '%sustainable%'
	 OR LOWER(description) LIKE '%sustainably%'
	 OR LOWER(description) LIKE '%sustainability%'
	 OR LOWER(description) LIKE '%recycled%'
	 OR LOWER(description) LIKE '%organic%'
	 OR LOWER(description) LIKE '%upcycled%'
	 OR LOWER(description) LIKE '%upcycling%';

-- Trend Over Time (Social)
SELECT
	DATE_TRUNC('month', date) AS month,
	COUNT(*) AS sustainable_posts
FROM social
WHERE LOWER(content) LIKE '%sustainable%'
	 OR LOWER(content) LIKE '%sustainably%'
	 OR LOWER(content) LIKE '%sustainability%'
	 OR LOWER(content) LIKE '%recycled%'
	 OR LOWER(content) LIKE '%organic%'
	 OR LOWER(content) LIKE '%upcycled%'
	 OR LOWER(content) LIKE '%upcycling%'
GROUP BY month
ORDER BY month;

-- Trend Over Time (E-commerce)
SELECT
	DATE_TRUNC('month', date) AS month,
	COUNT(*) AS sustainable_products
FROM product_dimensions
WHERE LOWER(description) LIKE '%sustainable%'
	 OR LOWER(description) LIKE '%sustainably%'
	 OR LOWER(description) LIKE '%sustainability%'
	 OR LOWER(description) LIKE '%recycled%'
	 OR LOWER(description) LIKE '%organic%'
	 OR LOWER(description) LIKE '%upcycled%'
	 OR LOWER(description) LIKE '%upcycling%'
GROUP BY month
ORDER BY month;

-- Segment Analysis: Social Engagement by Platform
SELECT
	platform,
	COUNT(*) AS sustainable_posts,
	AVG(likes) AS avg_likes,
	AVG(comments) AS avg_comments,
	AVG(shares) AS avg_shares
FROM social
WHERE LOWER(content) LIKE '%sustainable%'
	 OR LOWER(content) LIKE '%sustainably%'
	 OR LOWER(content) LIKE '%sustainability%'
	 OR LOWER(content) LIKE '%recycled%'
	 OR LOWER(content) LIKE '%organic%'
	 OR LOWER(content) LIKE '%upcycled%'
	 OR LOWER(content) LIKE '%upcycling%'
GROUP BY platform
ORDER BY avg_likes DESC;

-- Segment Analysis: Sustainable Products by Category
SELECT
	category,
	COUNT(*) AS sustainable_products
FROM product_dimensions
WHERE LOWER(description) LIKE '%sustainable%'
	 OR LOWER(description) LIKE '%sustainably%'
	 OR LOWER(description) LIKE '%sustainability%'
	 OR LOWER(description) LIKE '%recycled%'
	 OR LOWER(description) LIKE '%organic%'
	 OR LOWER(description) LIKE '%upcycled%'
	 OR LOWER(description) LIKE '%upcycling%'
GROUP BY category
ORDER BY sustainable_products DESC;

-- Penetration Metric: Social
SELECT
	100.0 * SUM(
		CASE WHEN LOWER(content) LIKE '%sustainable%'
					 OR LOWER(content) LIKE '%sustainably%'
					 OR LOWER(content) LIKE '%sustainability%'
					 OR LOWER(content) LIKE '%recycled%'
					 OR LOWER(content) LIKE '%organic%'
					 OR LOWER(content) LIKE '%upcycled%'
					 OR LOWER(content) LIKE '%upcycling%'
				 THEN 1 ELSE 0 END
	) / COUNT(*) AS sustainability_penetration_pct
FROM social;

-- 8. Penetration Metric: E-commerce
SELECT
	100.0 * SUM(
		CASE WHEN LOWER(description) LIKE '%sustainable%'
					 OR LOWER(description) LIKE '%sustainably%'
					 OR LOWER(description) LIKE '%sustainability%'
					 OR LOWER(description) LIKE '%recycled%'
					 OR LOWER(description) LIKE '%organic%'
					 OR LOWER(description) LIKE '%upcycled%'
					 OR LOWER(description) LIKE '%upcycling%'
				 THEN 1 ELSE 0 END
	) / COUNT(*) AS sustainability_penetration_pct
FROM product_dimensions;

-- Additional Metric: Engagement Rate (Social)
SELECT
	AVG((likes + comments + shares) * 1.0 / NULLIF(followers, 0)) AS avg_engagement_rate
FROM social
WHERE LOWER(content) LIKE '%sustainable%'
	 OR LOWER(content) LIKE '%sustainably%'
	 OR LOWER(content) LIKE '%sustainability%'
	 OR LOWER(content) LIKE '%recycled%'
	 OR LOWER(content) LIKE '%organic%'
	 OR LOWER(content) LIKE '%upcycled%'
	 OR LOWER(content) LIKE '%upcycling%';
