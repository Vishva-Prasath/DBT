WITH bronze_sles AS
(
    SELECT 
        sales_id,
        gross_amount,
        customer_sk,
        {{ multiply('unit_price','quantity') }} AS calculated_gross_amount,
        product_sk,
        payment_method
            
    FROM
        {{ ref('bronze_sales') }}
),

product AS
(
    SELECT 
        product_sk,
        category
    FROM
        {{ ref('bronze_dim_product') }}
),

customer AS
(
    SELECT 
        customer_sk,
        gender
    FROM
        {{ ref('bronze_dim_customer') }}

),
joinned_query AS(

SELECT
    sales.sales_id,
    sales.gross_amount,
    sales.payment_method,
    product.category,
    customer.gender
FROM
    bronze_sles AS sales
JOIN        
    product
ON
    sales.product_sk = product.product_sk
JOIN
    customer
ON
    sales.customer_sk = customer.customer_sk        
)
SELECT
    category,
    gender, 
    sum(gross_amount) AS total_gross_amount
FROM
    joinned_query   
GROUP BY
    category,       
    gender
ORDER BY
    total_gross_amount DESC

