-- Part 2a, Question 1
    WITH successful_orders AS (
        SELECT e.customer_id, -- customer_id present in both events and orders tables 
            o.order_id -- order_id FROM orders table AS specified by INNER JOIN
        FROM alt_school.events e 
            INNER JOIN alt_school.orders o USING (customer_id) 
        WHERE e.event_data ->> 'status' = 'success'
    ) 
    -- main query 
    SELECT
        li.item_id AS product_id, -- this was pulled FROM the item_id in line_items table which is a foreign key FROM the products table
        (SELECT p.name FROM alt_school.products p WHERE p.id = li.item_id) AS product_name, 
        SUM(li.quantity) AS num_times_in_successful_orders 
    FROM successful_orders s 
        INNER JOIN alt_school.line_items li USING (order_id) 
    GROUP BY li.item_id
    ORDER BY num_times_in_successful_orders DESC -- organize query results FROM most to least ordered items
    LIMIT 1; -- this ensures that the query returns only the most ordered item


-- Part 2a, Question 2
    WITH spender_details AS (
        SELECT e.customer_id,
            CAST(e.event_data ->> 'item_id' AS INTEGER) AS item_id, 
            CAST(e.event_data ->> 'quantity' AS INTEGER) AS quantity, 
            COUNT(e.event_data ->> 'item_id') OVER (PARTITION BY e.event_data ->> 'item_id', e.customer_id) AS item_num -- USING window function in order to keep specific event data on rows WITH items that were in the cart during checkout
        FROM alt_school.events e
        WHERE 
            e.customer_id IN (SELECT e.customer_id FROM alt_school.events e WHERE e.event_data ->> 'status' = 'success') -- USING this subquery so AS to work only WITH customers who made a successful checkout
            AND 
            e.event_data ->> 'event_type' IN ('add_to_cart', 'remove_from_cart') -- get only 'add to cart' and 'remove FROM cart' rows to determine customers items in cart during checkout
        ORDER BY e.customer_id
    ),
    expenditures_per_customer AS (
        SELECT s.customer_id,
            (s.quantity * p.price) AS amount_per_item
        FROM spender_details AS s 
            INNER JOIN alt_school.products p ON s.item_id = p.id
        WHERE s.item_num = 1 -- ensure that the item is still in the cart at the time of checkout
        ORDER BY s.customer_id	
    )
    -- main query
    SELECT es.customer_id,
        c.location,
        sum(es.amount_per_item) AS total_spend -- adds up customers total from amount spent per item
    FROM expenditures_per_customer AS es 
        INNER JOIN alt_school.customers c USING (customer_id) --joining with customer table to get the location of each customer
    GROUP BY es.customer_id, c.location
    ORDER BY total_spend DESC
    LIMIT 5;


-- Part 2b, Question 1
    SELECT c.location,
        COUNT(e.customer_id) AS checkout_count  -- SELECT columns AS specified by the question
    FROM alt_school.events e 
        INNER JOIN alt_school.customers c USING (customer_id)
    WHERE e.event_data ->> 'status' = 'success' -- ensure that the customers have at least one successful checkout 
    GROUP BY c.location -- COUNT per country
    ORDER BY checkout_count DESC
    LIMIT 1;


-- Part 2b, Question 2
    SELECT e.customer_id,
        COUNT(e.event_data) AS num_events -- COUNT number of events before abandonment
    FROM alt_school.events e
    WHERE 
        e.customer_id NOT IN (SELECT customer_id FROM alt_school.events WHERE e.event_data ->> 'status' = 'success') -- this filters out customers who have made a successful checkout
        AND 
        e.event_data ->> 'event_type' != 'visit' -- this ensures that visit event_types are excluded FROM the query set
    GROUP BY e.customer_id
    ORDER BY num_events DESC;


--Part 2b, Question 3
    WITH visits_per_customers AS (
        SELECT e.customer_id,
            COUNT(DISTINCT e.event_data) AS num_visits 
        FROM alt_school.events e
        WHERE 
            e.customer_id IN (SELECT e.customer_id FROM alt_school.events e WHERE e.event_data ->> 'status' = 'success') -- using this subquery so as to select only customers who made a successful checkout
            AND 
            e.event_data ->> 'event_type' = 'visit' -- ensures that the only visit event type is counted
        GROUP BY e.customer_id
    )
    -- main query
    SELECT ROUND(AVG(v.num_visits), 2) AS average_visits -- the ROUND function, rounds up the resulting average to 2 decimal place as required
    FROM visits_per_customers v;
