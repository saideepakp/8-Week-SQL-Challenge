# 🥑 Case Study #3 - Foodie-Fi

## 📚 Table of Contents
- [Business Context](#-business-context)
- [Problem Statement](#-problem-statement)
- [Dataset](#-dataset)
- [Case Study Questions](#-case-study-questions)

---

## 📺 Business Context

Subscription based businesses are super popular and Danny realised that there was a large gap in the market — he wanted to create a new streaming service that only had food related content — something like Netflix but with only cooking shows!

Danny found a few smart friends to launch his new startup **Foodie-Fi** in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a **data driven mindset** and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

---

## ❓ Problem Statement

This case study focuses on using subscription-style digital data to answer important business questions around customer behaviour, plan distribution, churn, and upgrade patterns.

All datasets exist within the `foodie_fi` database schema — be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

---

## 🗃️ Dataset

Foodie-Fi has **2 key tables** within the `foodie_fi` schema:

### `plans`
Customers can choose which plan to join Foodie-Fi when they first sign up.

| plan_id | plan_name | price |
|---|---|---|
| 0 | Trial | $0.00 |
| 1 | Basic Monthly | $9.90 |
| 2 | Pro Monthly | $19.90 |
| 3 | Pro Annual | $199.00 |
| 4 | Churn | null |

**Plan details:**
- **Trial** — 7-day free trial, automatically continues to Pro Monthly unless the customer cancels, downgrades, or upgrades.
- **Basic** — Limited access, stream only (no downloads), available monthly at $9.90.
- **Pro** — No watch time limits, offline downloads available. $19.90/month or $199/year.
- **Churn** — When a customer cancels, a churn record is created with a `null` price. Access continues until the end of the current billing period.

---

### `subscriptions`
Captures the exact `start_date` for each `plan_id` per customer.

| customer_id | plan_id | start_date |
|---|---|---|
| 1 | 0 | 2020-08-01 |
| 1 | 1 | 2020-08-08 |
| 2 | 0 | 2020-09-20 |
| 2 | 3 | 2020-09-27 |
| 11 | 0 | 2020-11-19 |
| 11 | 4 | 2020-11-26 |
| 13 | 0 | 2020-12-15 |
| 13 | 1 | 2020-12-22 |
| 13 | 2 | 2021-03-29 |
| 15 | 0 | 2020-03-17 |
| 15 | 2 | 2020-03-24 |
| 15 | 4 | 2020-04-29 |
| 16 | 0 | 2020-05-31 |
| 16 | 1 | 2020-06-07 |
| 16 | 3 | 2020-10-21 |
| 18 | 0 | 2020-07-06 |
| 18 | 2 | 2020-07-13 |
| 19 | 0 | 2020-06-22 |
| 19 | 2 | 2020-06-29 |
| 19 | 3 | 2020-08-29 |

**Key behaviours:**
- If a customer **downgrades or cancels** — the higher plan remains active until the billing period ends. The `start_date` reflects when the new plan actually takes effect.
- If a customer **upgrades** from Basic to Pro or Annual — the higher plan takes effect **immediately**.
- When a customer **churns** — the `start_date` reflects the day they decided to cancel, though access continues until the period ends.

---

### Entity Relationship Diagram

```
┌─────────────────┐        ┌─────────────────────┐
│     plans       │        │    subscriptions     │
│─────────────────│        │─────────────────────│
│ plan_id (PK)    │◀───────│ customer_id          │
│ plan_name       │        │ plan_id (FK)         │
│ price           │        │ start_date           │
└─────────────────┘        └─────────────────────┘
```

---

## 📋 Case Study Questions

Questions are split into 3 sections:

### A. Customer Journey

Based on the 8 sample customers provided in the `subscriptions` table, write a brief description of each customer's onboarding journey.

> 💡 Try to keep descriptions concise — joining the `subscriptions` and `plans` tables will make this easier.

---

### B. Data Analysis Questions

| # | Question |
|---|---|
| 1 | How many customers has Foodie-Fi ever had? |
| 2 | What is the monthly distribution of `trial` plan `start_date` values? Use the start of the month as the group by value. |
| 3 | What plan `start_date` values occur after the year 2020? Show the breakdown by count of events for each `plan_name`. |
| 4 | What is the customer count and percentage of customers who have churned, rounded to 1 decimal place? |
| 5 | How many customers churned straight after their initial free trial — what percentage is this rounded to the nearest whole number? |
| 6 | What is the number and percentage of customer plans after their initial free trial? |
| 7 | What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`? |
| 8 | How many customers have upgraded to an annual plan in 2020? |
| 9 | How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi? |
| 10 | Can you further break down this average into 30 day periods (i.e. 0–30 days, 31–60 days, etc.)? |
| 11 | How many customers downgraded from a Pro Monthly to a Basic Monthly plan in 2020? |

---

> 💡 Before diving into analysis, it is recommended to explore the sample data and understand the plan progression logic — particularly around trial-to-paid conversions and churn behaviour.
