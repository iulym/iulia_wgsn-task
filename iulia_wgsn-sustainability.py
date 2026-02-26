# Sustainability Trend Analysis

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# LOAD DATA

# Update path if needed
DATA_PATH = "social.csv"

social = pd.read_csv(DATA_PATH)

print("Dataset loaded.")
print(social.head())


# DEFINE SUSTAINABILITY TREND (KEYWORD MATCH)

pattern = r"\b(sustainable|sustainably|sustainability|recycled|organic|upcycled|upcycling)\b"

social["sust_flag"] = social["CONTENT"].str.contains(
    pattern,
    case=False,
    na=False
).astype(int)

print("\nSustainability flag created.")

# DATE PROCESSING

social["POST_DATE"] = pd.to_datetime(social["POST_DATE"])

# Monthly time granularity
social["year_month"] = social["POST_DATE"].dt.to_period("M").astype(str)



# CREATE ENGAGEMENT METRIC

social["LIKES"] = social["LIKES"].fillna(0)
social["COMMENTS"] = social["COMMENTS"].fillna(0)

social["engagement"] = social["LIKES"] + social["COMMENTS"]

print("\nEngagement metric created.")


# TREND PENETRATION OVER TIME

penetration_time = (
    social.groupby("year_month")
    .agg(
        total_posts=("POST_ID", "nunique"),
        sust_posts=("sust_flag", "sum")
    )
    .reset_index()
)

penetration_time["penetration"] = (
    penetration_time["sust_posts"] /
    penetration_time["total_posts"]
)

print("\nPenetration over time:")
print(penetration_time.head())



# ENGAGEMENT COMPARISON (TREND VS NON-TREND)


engagement_compare = (
    social.groupby("sust_flag")
    .agg(
        posts=("POST_ID", "nunique"),
        avg_likes=("LIKES", "mean"),
        avg_comments=("COMMENTS", "mean"),
        avg_engagement=("engagement", "mean")
    )
)

print("\nEngagement comparison:")
print(engagement_compare)


# SEGMENT ANALYSIS

segment_engagement = (
    social.groupby(["SEGMENT", "sust_flag"])
    .agg(
        posts=("POST_ID", "nunique"),
        avg_engagement=("engagement", "mean"),
        total_engagement=("engagement", "sum")
    )
    .reset_index()
)

print("\nSegment engagement:")
print(segment_engagement)


# ENGAGEMENT LIFT (KEY METRIC)

trend = segment_engagement[segment_engagement["sust_flag"] == 1]
base = segment_engagement[segment_engagement["sust_flag"] == 0]

lift = trend.merge(base, on="SEGMENT", suffixes=("_trend", "_base"))

lift["engagement_lift"] = (
    lift["avg_engagement_trend"] /
    lift["avg_engagement_base"] - 1
)

print("\nEngagement lift by segment:")
print(lift[["SEGMENT", "engagement_lift"]])


# ADDITIONAL METRICS BEYOND PENETRATION

# Share of engagement
share_engagement = (
    social.groupby("sust_flag")["engagement"]
    .sum()
    .reset_index()
)

share_engagement["share"] = (
    share_engagement["engagement"] /
    share_engagement["engagement"].sum()
)

print("\nShare of engagement:")
print(share_engagement)

# Comment intensity (discussion depth)
social["comment_ratio"] = (
    social["COMMENTS"] /
    social["LIKES"].replace(0, np.nan)
)

print("\nComment ratio created.")


# E-COMMERCE METRICS

# Load e-commerce data
products = pd.read_csv("product_dimensions.csv")

# Sustainability flag for products
products["sust_flag"] = products["PRODUCT_DESCRIPTION"].str.contains(
    pattern, case=False, na=False
).astype(int)

# 1. Share of products containing sustainability keywords
share_sust_products = products["sust_flag"].mean()
print(f"\nShare of products with sustainability keywords: {share_sust_products:.2%}")

# 2. Distribution of sustainability positioning by style and retailer segment
sust_dist = (
    products[products["sust_flag"] == 1]
    .groupby(["STYLE", "RETAILER_SEGMENT"])
    ["PC_ID"].count()
    .reset_index()
    .rename(columns={"PC_ID": "sust_product_count"})
)
print("\nDistribution of sustainable products by STYLE and RETAILER_SEGMENT:")
print(sust_dist)


# VISUALISATIONS


sns.set(style="whitegrid")

# Penetration trend 
plt.figure(figsize=(10, 5))
sns.lineplot(
    data=penetration_time,
    x="year_month",
    y="penetration",
    marker="o"
)

plt.title("Sustainability Trend Penetration Over Time")
plt.xlabel("Month")
plt.ylabel("Penetration (%)")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()


# Engagement by segment
plt.figure(figsize=(8, 5))

sns.barplot(
    data=segment_engagement[segment_engagement["sust_flag"] == 1],
    x="SEGMENT",
    y="avg_engagement"
)

plt.title("Average Engagement on Sustainability Posts by Segment")
plt.xlabel("Segment")
plt.ylabel("Average Engagement")
plt.tight_layout()
plt.show()


# MOMENTUM (TREND GROWTH)

penetration_time["growth_rate"] = penetration_time["penetration"].pct_change()

print("\nTrend momentum:")
print(penetration_time[["year_month", "growth_rate"]])

# Visualize trend momentum (growth_rate)
plt.figure(figsize=(10, 5))
sns.lineplot(
    data=penetration_time,
    x="year_month",
    y="growth_rate",
    marker="o"
)
plt.title("Trend Momentum: Growth Rate Over Time")
plt.xlabel("Month")
plt.ylabel("Growth Rate")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# END
print("\nAnalysis complete.")
