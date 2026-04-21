# 🍕 Case Study #2 - Pizza Runner

## 📚 Table of Contents
- [Business Context](#-business-context)
- [Problem Statement](#-problem-statement)
- [Dataset](#-dataset)
- [Data Cleaning Notes](#-data-cleaning-notes)
- [Case Study Questions](#-case-study-questions)

---

## 🛵 Business Context

Did you know that over 115 million kilograms of pizza is consumed daily worldwide?

Danny was scrolling through his Instagram feed when something really caught his eye — *"80s Retro Styling and Pizza Is The Future!"*

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire — so he had one more genius idea to combine with it — he was going to Uberize it — and so **Pizza Runner** was launched!

Danny started by recruiting **"runners"** to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny's house) and maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

---

## ❓ Problem Statement

Danny requires further assistance to **clean his data** and apply some **basic calculations** so he can better direct his runners and optimise Pizza Runner's operations.

All datasets exist within the `pizza_runner` database schema — be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

---

## 🗃️ Dataset

Pizza Runner has **6 key tables** within the `pizza_runner` schema:

### `runners`
Shows the `registration_date` for each new runner.

| runner_id | registration_date |
|---|---|
| 1 | 2021-01-01 |
| 2 | 2021-01-03 |
| 3 | 2021-01-08 |
| 4 | 2021-01-15 |

---

### `customer_orders`
Captures customer pizza orders — 1 row per individual pizza per order. Contains `exclusions` (ingredients to remove) and `extras` (ingredients to add).

> ⚠️ The `exclusions` and `extras` columns require cleaning before use.

| order_id | customer_id | pizza_id | exclusions | extras | order_time |
|---|---|---|---|---|---|
| 1 | 101 | 1 | | | 2021-01-01 18:05:02 |
| 2 | 101 | 1 | | | 2021-01-01 19:00:52 |
| 3 | 102 | 1 | | | 2021-01-02 23:51:23 |
| 3 | 102 | 2 | NaN | | 2021-01-02 23:51:23 |
| 4 | 103 | 1 | 4 | | 2021-01-04 13:23:46 |
| 4 | 103 | 1 | 4 | | 2021-01-04 13:23:46 |
| 4 | 103 | 2 | 4 | | 2021-01-04 13:23:46 |
| 5 | 104 | 1 | null | 1 | 2021-01-08 21:00:29 |
| 6 | 101 | 2 | null | null | 2021-01-08 21:03:13 |
| 7 | 105 | 2 | null | 1 | 2021-01-08 21:20:29 |
| 8 | 102 | 1 | null | null | 2021-01-09 23:54:33 |
| 9 | 103 | 1 | 4 | 1, 5 | 2021-01-10 11:22:59 |
| 10 | 104 | 1 | null | null | 2021-01-11 18:34:49 |
| 10 | 104 | 1 | 2, 6 | 1, 4 | 2021-01-11 18:34:49 |

---

### `runner_orders`
Captures order assignments to runners. Not all orders are completed — orders can be cancelled by the restaurant or the customer.

> ⚠️ Known data quality issues exist in this table — check data types carefully.

| order_id | runner_id | pickup_time | distance | duration | cancellation |
|---|---|---|---|---|---|
| 1 | 1 | 2021-01-01 18:15:34 | 20km | 32 minutes | |
| 2 | 1 | 2021-01-01 19:10:54 | 20km | 27 minutes | |
| 3 | 1 | 2021-01-03 00:12:37 | 13.4km | 20 mins | NaN |
| 4 | 2 | 2021-01-04 13:53:03 | 23.4 | 40 | NaN |
| 5 | 3 | 2021-01-08 21:10:57 | 10 | 15 | NaN |
| 6 | 3 | null | null | null | Restaurant Cancellation |
| 7 | 2 | 2020-01-08 21:30:45 | 25km | 25mins | null |
| 8 | 2 | 2020-01-10 00:15:02 | 23.4 km | 15 minute | null |
| 9 | 2 | null | null | null | Customer Cancellation |
| 10 | 1 | 2020-01-11 18:50:20 | 10km | 10minutes | null |

---

### `pizza_names`
Maps each `pizza_id` to its name. Pizza Runner currently offers 2 pizzas.

| pizza_id | pizza_name |
|---|---|
| 1 | Meat Lovers |
| 2 | Vegetarian |

---

### `pizza_recipes`
Each pizza has a standard set of toppings defined by `topping_id` values.

| pizza_id | toppings |
|---|---|
| 1 | 1, 2, 3, 4, 5, 6, 8, 10 |
| 2 | 4, 6, 7, 9, 11, 12 |

---

### `pizza_toppings`
Maps each `topping_id` to its name.

| topping_id | topping_name |
|---|---|
| 1 | Bacon |
| 2 | BBQ Sauce |
| 3 | Beef |
| 4 | Cheese |
| 5 | Chicken |
| 6 | Mushrooms |
| 7 | Onions |
| 8 | Pepperoni |
| 9 | Peppers |
| 10 | Salami |
| 11 | Tomatoes |
| 12 | Tomato Sauce |

---

### Entity Relationship Diagram

```
┌─────────────────┐       ┌──────────────────┐
│     runners     │       │  customer_orders  │
│─────────────────│       │──────────────────│
│ runner_id (PK)  │       │ order_id         │
│ registration_   │       │ customer_id      │
│   date          │       │ pizza_id (FK)    │
└─────────────────┘       │ exclusions       │
        │                 │ extras           │
        │                 │ order_time       │
        ▼                 └──────────────────┘
┌─────────────────┐               │
│  runner_orders  │               │ pizza_id
│─────────────────│               ▼
│ order_id (FK)   │       ┌──────────────────┐
│ runner_id (FK)  │       │   pizza_names    │
│ pickup_time     │       │──────────────────│
│ distance        │       │ pizza_id (PK)    │
│ duration        │       │ pizza_name       │
│ cancellation    │       └──────────────────┘
└─────────────────┘               │
                                  │ pizza_id
                                  ▼
                          ┌──────────────────┐      ┌──────────────────┐
                          │  pizza_recipes   │      │  pizza_toppings  │
                          │──────────────────│      │──────────────────│
                          │ pizza_id (FK)    │─────▶│ topping_id (PK)  │
                          │ toppings         │      │ topping_name     │
                          └──────────────────┘      └──────────────────┘
```

---

## 🧹 Data Cleaning Notes

Before answering any questions, the following data quality issues must be addressed:

- **`customer_orders`** — `exclusions` and `extras` columns contain a mix of `null`, `'null'` (as string), and `NaN` values. These should be standardised to `NULL`.
- **`runner_orders`** — `distance` and `duration` columns contain inconsistent formatting (e.g. `20km`, `25mins`, `15 minute`). Units should be stripped and columns cast to numeric types. `cancellation` column also contains mixed `null`/`'null'`/`NaN` values.

---

## 📋 Case Study Questions

Questions are grouped into 5 focus areas:

### A. Pizza Metrics

| # | Question |
|---|---|
| 1 | How many pizzas were ordered? |
| 2 | How many unique customer orders were made? |
| 3 | How many successful orders were delivered by each runner? |
| 4 | How many of each type of pizza was delivered? |
| 5 | How many Vegetarian and Meat Lovers were ordered by each customer? |
| 6 | What was the maximum number of pizzas delivered in a single order? |
| 7 | For each customer, how many delivered pizzas had at least 1 change and how many had no changes? |
| 8 | How many pizzas were delivered that had both exclusions and extras? |
| 9 | What was the total volume of pizzas ordered for each hour of the day? |
| 10 | What was the volume of orders for each day of the week? |

---

### B. Runner and Customer Experience

| # | Question |
|---|---|
| 1 | How many runners signed up for each 1 week period? (i.e. week starts `2021-01-01`) |
| 2 | What was the average time in minutes it took for each runner to arrive at Pizza Runner HQ to pick up the order? |
| 3 | Is there any relationship between the number of pizzas and how long the order takes to prepare? |
| 4 | What was the average distance travelled for each customer? |
| 5 | What was the difference between the longest and shortest delivery times for all orders? |
| 6 | What was the average speed for each runner for each delivery and do you notice any trend? |
| 7 | What is the successful delivery percentage for each runner? |

---

### C. Ingredient Optimisation

| # | Question |
|---|---|
| 1 | What are the standard ingredients for each pizza? |
| 2 | What was the most commonly added extra? |
| 3 | What was the most common exclusion? |
| 4 | Generate an order item for each record in the `customer_orders` table (e.g. `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`) |
| 5 | Generate an alphabetically ordered comma separated ingredient list for each pizza order and add `2x` in front of any relevant ingredients (e.g. `Meat Lovers: 2xBacon, Beef, ..., Salami`) |
| 6 | What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first? |

---

### D. Pricing and Ratings

| # | Question |
|---|---|
| 1 | If a Meat Lovers pizza costs $12 and Vegetarian $10 with no charges for changes — how much money has Pizza Runner made so far? |
| 2 | What if there was an additional $1 charge for any pizza extras (including cheese)? |
| 3 | Design an additional ratings table that allows customers to rate their runner (1–5) and insert sample data for each successful order. |
| 4 | Using the ratings table, join all relevant information for successful deliveries: `customer_id`, `order_id`, `runner_id`, `rating`, `order_time`, `pickup_time`, time between order and pickup, delivery duration, average speed, and total pizzas. |
| 5 | If Meat Lovers = $12 and Vegetarian = $10 with no extras cost, and runners are paid $0.30 per km — how much money does Pizza Runner have left over after deliveries? |

---


> 💡 Each question can be answered using **Postgre SQL**. Before writing any queries, make sure to clean the `customer_orders` and `runner_orders` tables first.
