# 🍜 Case Study #1 - Danny's Diner

## 📚 Table of Contents
- [Business Context](#-business-context)
- [Problem Statement](#-problem-statement)
- [Dataset](#-dataset)
- [Case Study Questions](#-case-study-questions)

---

## 🏪 Business Context

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: **sushi**, **curry**, and **ramen**.

Danny's Diner is in need of your assistance to help the restaurant stay afloat — the restaurant has captured some very basic data from their few months of operation but has no idea how to use their data to help run the business.

---

## ❓ Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their:

- **Visiting patterns** — how often do customers come in?
- **Spending behaviour** — how much money have they spent?
- **Menu preferences** — which items are their favourites?

Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He also plans on using these insights to help decide whether he should **expand the existing customer loyalty program**, and needs help generating basic datasets so his team can inspect the data without needing to use SQL.

---

## 🗃️ Dataset

Danny has shared **3 key datasets** for this case study:

### `sales`
Captures all customer-level purchases with the corresponding `order_date` and `product_id`.

### `menu`
Maps the `product_id` to the actual `product_name` and `price` of each menu item.

### `members`
Captures the `join_date` when a customer joined the beta version of the loyalty program.

### Entity Relationship Diagram

```
┌─────────────────┐        ┌─────────────────┐
│     sales       │        │     menu        │
│─────────────────│        │─────────────────│
│ customer_id     │        │ product_id (PK) │
│ order_date      │───────▶│ product_name    │
│ product_id (FK) │        │ price           │
└─────────────────┘        └─────────────────┘
        │
        │  customer_id
        ▼
┌─────────────────┐
│    members      │
│─────────────────│
│ customer_id     │
│ join_date       │
└─────────────────┘
```

---

## 📋 Case Study Questions

| # | Question |
|---|---|
| 1 | What is the total amount each customer spent at the restaurant? |
| 2 | How many days has each customer visited the restaurant? |
| 3 | What was the first item from the menu purchased by each customer? |
| 4 | What is the most purchased item on the menu and how many times was it purchased by all customers? |
| 5 | Which item was the most popular for each customer? |
| 6 | Which item was purchased first by the customer after they became a member? |
| 7 | Which item was purchased just before the customer became a member? |
| 8 | What is the total items and amount spent for each member before they became a member? |
| 9 | If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have? |
| 10 | In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January? |

---

> 💡 Each of the questions above can be answered using  **Postgre SQL**.
