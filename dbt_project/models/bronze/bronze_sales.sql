{{ config(materialized = 'view') }}

SELECT 
*
FROM 
{{ source('source', 'fact_sales') }}

{# dbt_dev.source.fact_sales #}