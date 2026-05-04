# 🏦 Case Study #4 - Data Bank

## 📚 Table of Contents
- [Business Context](#-business-context)
- [Problem Statement](#-problem-statement)
- [Dataset](#-dataset)
- [Case Study Questions](#-case-study-questions)

---

## 💡 Business Context

There is a new innovation in the financial industry called **Neo-Banks** — new age digital-only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world… so he decides to launch a new initiative — **Data Bank!**

Data Bank runs just like any other digital bank — but it isn't only for banking activities. They also have the world's most secure distributed data storage platform! Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts.

---

## ❓ Problem Statement

The management team at Data Bank want to:

- **Increase their total customer base**
- **Track how much data storage their customers will need**

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better **forecast and plan for their future developments**.

All datasets exist within the `data_bank` database schema — be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

---

## 🗃️ Dataset

Data Bank has **3 key tables** within the `data_bank` schema:

### `regions`
Data Bank operates off a network of nodes across the globe — similar to bank branches. This table maps each `region_id` to its `region_name`.

| region_id | region_name |
|---|---|
| 1 | Africa |
| 2 | America |
| 3 | Asia |
| 4 | Europe |
| 5 | Oceania |

---

### `customer_nodes`
Customers are randomly distributed across nodes according to their region. This distribution changes frequently to reduce the risk of security breaches.

| customer_id | region_id | node_id | start_date | end_date |
|---|---|---|---|---|
| 1 | 3 | 4 | 2020-01-02 | 2020-01-03 |
| 2 | 3 | 5 | 2020-01-03 | 2020-01-17 |
| 3 | 5 | 4 | 2020-01-27 | 2020-02-18 |
| 4 | 5 | 4 | 2020-01-07 | 2020-01-19 |
| 5 | 3 | 3 | 2020-01-15 | 2020-01-23 |
| 6 | 1 | 1 | 2020-01-11 | 2020-02-06 |
| 7 | 2 | 5 | 2020-01-20 | 2020-02-04 |
| 8 | 1 | 2 | 2020-01-15 | 2020-01-28 |
| 9 | 4 | 5 | 2020-01-21 | 2020-01-25 |
| 10 | 3 | 4 | 2020-01-13 | 2020-01-14 |

---

### `customer_transactions`
Stores all customer deposits, withdrawals and purchases made using their Data Bank debit card.

| customer_id | txn_date | txn_type | txn_amount |
|---|---|---|---|
| 429 | 2020-01-21 | deposit | 82 |
| 155 | 2020-01-10 | deposit | 712 |
| 398 | 2020-01-01 | deposit | 196 |
| 255 | 2020-01-14 | deposit | 563 |
| 185 | 2020-01-29 | deposit | 626 |
| 309 | 2020-01-13 | deposit | 995 |
| 312 | 2020-01-20 | deposit | 485 |
| 376 | 2020-01-03 | deposit | 706 |
| 188 | 2020-01-13 | deposit | 601 |
| 138 | 2020-01-11 | deposit | 520 |

---

### Entity Relationship Diagram

```
┌─────────────────┐        ┌──────────────────────┐
│    regions      │        │   customer_nodes      │
│─────────────────│        │──────────────────────│
│ region_id (PK)  │◀───────│ customer_id (FK)     │◀──┐
│ region_name     │        │ region_id (FK)        │   │
└─────────────────┘        │ node_id              │   │
                           │ start_date           │   │ customer_id
                           │ end_date             │   │
                           └──────────────────────┘   │
                                                       │
                           ┌──────────────────────┐   │
                           │ customer_transactions │   │
                           │──────────────────────│   │
                           │ customer_id          │───┘
                           │ txn_date             │
                           │ txn_type             │
                           │ txn_amount           │
                           └──────────────────────┘
```

---

## 📋 Case Study Questions

Questions are split into 3 sections:

### A. Customer Nodes Exploration

| # | Question |
|---|---|
| 1 | How many unique nodes are there on the Data Bank system? |
| 2 | What is the number of nodes per region? |
| 3 | How many customers are allocated to each region? |
| 4 | How many days on average are customers reallocated to a different node? |
| 5 | What is the median, 80th and 95th percentile for the reallocation days metric for each region? |

---

### B. Customer Transactions

| # | Question |
|---|---|
| 1 | What is the unique count and total amount for each transaction type? |
| 2 | What is the average total historical deposit counts and amounts for all customers? |
| 3 | For each month — how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month? |
| 4 | What is the closing balance for each customer at the end of the month? |
| 5 | What is the percentage of customers who increase their closing balance by more than 5%? |

---

### C. Data Allocation Challenge

The Data Bank team wants to run an experiment where different groups of customers are allocated data using 3 different options:

| Option | Description |
|---|---|
| **Option 1** | Data is allocated based on the amount of money at the end of the previous month |
| **Option 2** | Data is allocated based on the average amount of money kept in the account in the previous 30 days |
| **Option 3** | Data is updated in real-time |

To estimate how much data needs to be provisioned for each option, generate the following:

- Running customer balance column that includes the impact of each transaction
- Customer balance at the end of each month
- Minimum, average and maximum values of the running balance for each customer

Using all available data — **how much data would have been required for each option on a monthly basis?**

---

> 💡 Pay close attention to the `end_date` column in the `customer_nodes` table — some records contain a far-future sentinel date used to indicate a currently active node assignment. Filter these out where necessary.
