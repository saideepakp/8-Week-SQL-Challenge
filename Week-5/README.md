# 🛒 Case Study #5 - Data Mart

## 📚 Table of Contents
- [Business Context](#-business-context)
- [Problem Statement](#-problem-statement)
- [Dataset](#-dataset)
- [Case Study Questions](#-case-study-questions)

---

## 🌿 Business Context

Data Mart is Danny's latest venture — an online supermarket that specialises in fresh produce with international operations across multiple regions.

In **June 2020**, large scale supply changes were made at Data Mart. All Data Mart products now use **sustainable packaging methods** in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and its separate business areas.

---

## ❓ Problem Statement

The key business questions Danny wants answered are:

- What was the **quantifiable impact** of the changes introduced in June 2020?
- Which **platform, region, segment and customer types** were the most impacted by this change?
- What can we do about **future introduction of similar sustainability updates** to minimise impact on sales?

All datasets exist within the `data_mart` database schema — be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

---

## 🗃️ Dataset

This case study has a **single table**: `data_mart.weekly_sales`

### `weekly_sales`

Each record represents a specific aggregated slice of the underlying sales data, rolled up into a `week_date` value which represents the **start of the sales week**.

| week_date | region | platform | segment | customer_type | transactions | sales |
|---|---|---|---|---|---|---|
| 9/9/20 | OCEANIA | Shopify | C3 | New | 610 | 110033.89 |
| 29/7/20 | AFRICA | Retail | C1 | New | 110692 | 3053771.19 |
| 22/7/20 | EUROPE | Shopify | C4 | Existing | 24 | 8101.54 |
| 13/5/20 | AFRICA | Shopify | null | Guest | 5287 | 1003301.37 |
| 24/7/19 | ASIA | Retail | C1 | New | 127342 | 3151780.41 |
| 10/7/19 | CANADA | Shopify | F3 | New | 51 | 8844.93 |
| 26/6/19 | OCEANIA | Retail | C3 | New | 152921 | 5551385.36 |
| 29/5/19 | SOUTH AMERICA | Shopify | null | New | 53 | 10056.20 |
| 22/8/18 | AFRICA | Retail | null | Existing | 31721 | 1718863.58 |
| 25/7/18 | SOUTH AMERICA | Retail | null | New | 2136 | 81757.91 |

### Column Dictionary

| Column | Description |
|---|---|
| `week_date` | Start date of the sales week |
| `region` | The international region (e.g. AFRICA, ASIA, OCEANIA) |
| `platform` | Sales channel — either `Retail` or `Shopify` |
| `segment` | Customer segment code combining demographic and age band (e.g. `C1`, `F3`) |
| `customer_type` | Whether the customer is `New`, `Existing`, or a `Guest` |
| `transactions` | Count of unique purchases made through Data Mart |
| `sales` | Actual dollar amount of purchases |

### Segment Mapping

**Age Band** (based on the number in the segment value):

| Segment Number | Age Band |
|---|---|
| 1 | Young Adults |
| 2 | Middle Aged |
| 3 or 4 | Retirees |

**Demographic** (based on the first letter in the segment value):

| Segment Letter | Demographic |
|---|---|
| C | Couples |
| F | Families |

---

### Entity Relationship Diagram

```
┌───────────────────────────────────┐
│       data_mart.weekly_sales      │
│───────────────────────────────────│
│ week_date      DATE               │
│ region         VARCHAR            │
│ platform       VARCHAR            │
│ segment        VARCHAR            │
│ customer_type  VARCHAR            │
│ transactions   INTEGER            │
│ sales          DECIMAL            │
└───────────────────────────────────┘
```

> 📝 This case study has only one table — all analysis is derived from `weekly_sales` alone.

---

## 📋 Case Study Questions

Questions are split into 3 sections:

### 1. Data Cleansing Steps

In a single query, create a new table `data_mart.clean_weekly_sales` with the following transformations:

| Task | Description |
|---|---|
| Date format | Convert `week_date` to a `DATE` format |
| `week_number` | Add as the 2nd column — the week number of the year for each `week_date` |
| `month_number` | Add as the 3rd column — the calendar month for each `week_date` |
| `calendar_year` | Add as the 4th column — containing `2018`, `2019`, or `2020` |
| `age_band` | Add after `segment` using the segment number mapping above |
| `demographic` | Add using the segment letter mapping above |
| Null handling | Replace all `null` string values with `'unknown'` in `segment`, `age_band`, and `demographic` |
| `avg_transaction` | Add as `sales / transactions` rounded to 2 decimal places |

---

### 2. Data Exploration

| # | Question |
|---|---|
| 1 | What day of the week is used for each `week_date` value? |
| 2 | What range of week numbers are missing from the dataset? |
| 3 | How many total transactions were there for each year in the dataset? |
| 4 | What is the total sales for each region for each month? |
| 5 | What is the total count of transactions for each platform? |
| 6 | What is the percentage of sales for Retail vs Shopify for each month? |
| 7 | What is the percentage of sales by demographic for each year in the dataset? |
| 8 | Which `age_band` and `demographic` values contribute the most to Retail sales? |
| 9 | Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not — how would you calculate it instead? |

---

### 3. Before & After Analysis

This technique is used to inspect the impact of an important event before and after a certain point in time.

**Baseline date: `2020-06-15`** — the week the sustainable packaging changes came into effect.

- All `week_date` values from `2020-06-15` onwards = **after** the change
- All `week_date` values before `2020-06-15` = **before** the change

| # | Question |
|---|---|
| 1 | What is the total sales for the **4 weeks before and after** `2020-06-15`? What is the growth or reduction rate in actual values and percentage? |
| 2 | What about the **entire 12 weeks before and after**? |
| 3 | How do the sale metrics for these 2 periods compare with the **same periods in 2018 and 2019**? |

---

> 💡 Complete the **Data Cleansing** step first and work from `clean_weekly_sales` for all subsequent questions.
