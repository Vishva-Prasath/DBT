# dbt Data Transformation Project

An end-to-end **dbt (Data Build Tool) project using Databricks** that demonstrates modern data transformation and analytics engineering practices.

The project implements a layered **Bronze-Silver-Gold architecture** and covers dbt fundamentals including source definitions, model dependencies, Jinja templating, reusable macros, data quality tests, seed data, snapshots, and Databricks environment configuration.

## Project Overview

This project demonstrates how dbt can be used to transform and manage data inside Databricks using SQL and Jinja.

The project follows a layered architecture:

```text
Source Data
    |
    v
+----------------+
|     Source     |
| fact_sales     |
| fact_returns   |
| dimensions     |
| items          |
+----------------+
        |
        v
+----------------+
|     Bronze     |
| Raw/Initial    |
| Transformations|
+----------------+
        |
        v
+----------------+
|     Silver     |
| Business       |
| Transformations|
+----------------+
        |
        v
+----------------+
|      Gold      |
| Analytics /    |
| Curated Data   |
+----------------+
```

The project also demonstrates dbt features that support maintainability and data quality:

* Source management using `sources.yml`
* Model dependencies using `ref()`
* Jinja templating
* Custom dbt macros
* Generic data quality tests
* Built-in dbt tests
* Seed data
* dbt snapshots
* Schema configuration
* Bronze, Silver and Gold schemas
* Databricks SQL Warehouse integration

## Technology Stack

| Technology | Purpose                                       |
| ---------- | --------------------------------------------- |
| dbt        | Data transformation and analytics engineering |
| Databricks | Data platform and SQL execution               |
| SQL        | Data transformation                           |
| Jinja      | Dynamic SQL and templating                    |
| YAML       | Project configuration and data tests          |
| CSV        | Seed/reference data                           |
| Git        | Version control                               |

## Architecture

### Source Layer

The project defines source tables in:

```text
models/source/sources.yml
```

The configured source tables include:

* `fact_sales`
* `fact_returns`
* `dim_customer`
* `dim_date`
* `dim_store`
* `dim_product`
* `items`

The source database/catalog is dynamically obtained from the dbt target configuration.

Example:

```sql
{{ source('source', 'fact_sales') }}
```

This allows dbt to maintain an explicit dependency between transformation models and their source tables.

---

### Bronze Layer

The Bronze layer provides the initial transformation layer over the source data.

Models include:

```text
bronze_dim_customer
bronze_dim_date
bronze_dim_product
bronze_dim_store
bronze_fact_returns
bronze_sales
```

Most Bronze models directly select data from their corresponding source tables.

Example:

```sql
SELECT *
FROM {{ source('source', 'fact_sales') }}
```

The Bronze models are configured primarily as tables, with model-level configuration also demonstrated for individual models.

---

### Silver Layer

The Silver layer contains business-oriented transformations and joins.

The primary model is:

```text
silver_salesinfo.sql
```

This model demonstrates:

* Referencing Bronze models using `ref()`
* Joining sales with customer and product dimensions
* Reusable macros
* Calculated columns
* Aggregation
* Business-level transformation
* Grouping by product category and customer gender

Example dependency:

```text
bronze_sales
      |
      +----> silver_salesinfo
      |
bronze_dim_product
      |
      +----> silver_salesinfo
      |
bronze_dim_customer
      |
      +----> silver_salesinfo
```

The resulting model calculates aggregated gross sales by:

* Product category
* Customer gender

---

### Gold Layer

The Gold layer contains curated data intended for downstream analytics.

The project includes:

```text
source_gold_items.sql
```

This model demonstrates deduplication using a window function.

```sql
ROW_NUMBER() OVER (
    PARTITION BY id
    ORDER BY updateDate DESC
)
```

The latest record for each `id` is retained.

This provides a simple example of preparing source data for consumption while handling duplicate records.

## dbt Macros

Reusable macros are stored under:

```text
macros/
```

### multiply.sql

The `multiply` macro provides a reusable expression for multiplying two columns or values.

```sql
{% macro multiply(col1, col2)%}
    {{ col1 }} * {{ col2 }}
{% endmacro %}
```

It is used in the Silver model:

```sql
{{ multiply('unit_price','quantity') }}
```

This demonstrates how repeated SQL expressions can be abstracted into reusable dbt components.

### generate_schema.sql

The project also contains a custom `generate_schema_name` macro.

It controls how custom schemas are generated based on the dbt target configuration.

This demonstrates how dbt's default schema-generation behavior can be customized.

## Jinja Templating

The project contains Jinja examples under:

```text
analyses/jinja_1.sql
```

The example demonstrates:

* Variables
* Lists
* `for` loops
* `if/else` conditions
* Dynamic SQL generation

Example:

```jinja
{% set fruits = ["apple", "mango", "grapes"] %}

{% for i in fruits %}
    {% if i != "mango" %}
        {{ i }}
    {% else %}
        I love {{ i }}
    {% endif %}
{% endfor %}
```

This demonstrates how Jinja can introduce programming-style logic into dbt SQL files.

## Data Quality Testing

The project demonstrates both built-in and custom dbt tests.

Tests are configured through:

```text
models/bronze/properties.yml
```

### Built-in Tests

The `bronze_sales` model contains tests for:

#### Unique

```yaml
- unique
```

Ensures that `sales_id` values are unique.

#### Not Null

```yaml
- not_null
```

Ensures that required `sales_id` values are populated.

#### Accepted Values

The `payment_method` column is validated against expected values:

```yaml
values:
  - Cash
  - Digital Wallet
  - Card
  - Gift Card
```

The test is configured with warning severity.

### Custom Generic Test

The project defines:

```text
tests/generic/generic_non_negative.sql
```

The test validates that numeric values are not negative.

```sql
{% test generic_non_negative(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} < 0

{% endtest %}
```

It is applied to:

```text
bronze_sales.gross_amount
```

This demonstrates how reusable custom data quality tests can be created in dbt.

### Singular Test

The project also contains:

```text
tests/non_negative_test.sql
```

This demonstrates a model-specific SQL test.

## Seeds

Reference data is stored under:

```text
seeds/
```

The project contains:

```text
lookup.csv
```

Example data:

```text
customer_id,customer_name,customer_email
1,John Smith,john.smith@email.com
2,Sarah Johnson,sarah.johnson@email.com
3,Michael Brown,michael.brown@email.com
4,Emily Davis,emily.davis@email.com
5,David Wilson,david.wilson@email.com
```

Seeds allow static CSV data to be loaded into the data platform and referenced by dbt models.

## Snapshots

The project demonstrates dbt snapshots using:

```text
snapshots/gold_items.yml
```

The snapshot tracks changes to the Gold items dataset using:

* `id` as the unique key
* `updateDate` as the timestamp column
* Timestamp-based change detection
* A Gold schema

Conceptually:

```text
Source Items
     |
     v
Deduplication
     |
     v
Gold Items
     |
     v
dbt Snapshot
     |
     +---- Historical versions
```

This allows historical changes to records to be captured over time.

## Project Configuration

The main dbt configuration is available in:

```text
dbt_project/dbt_project.yml
```

The project defines paths for:

```text
models
analyses
tests
seeds
macros
snapshots
```

The models are organized into three schemas:

| Layer  | Materialization | Schema |
| ------ | --------------- | ------ |
| Bronze | Table           | bronze |
| Silver | View            | silver |
| Gold   | View            | gold   |

Seeds are configured to use the Bronze schema.

## Databricks Configuration

The project uses the Databricks dbt adapter.

The profile contains separate environments:

```text
dev
prod
```

Each environment contains configuration for:

* Databricks catalog
* Databricks SQL Warehouse
* Schema
* Threads
* Authentication token

For security, credentials should never be committed to Git.

Replace:

```text
YOUR_DATABRICKS_TOKEN
```

with a secure authentication mechanism such as an environment variable or appropriate Databricks/dbt credential configuration.

## Folder Structure

```text
DBT-main/
│
├── .gitignore
├── .python-version
├── main.py
├── README.md
│
├── .vscode/
│   └── settings.json
│
├── logs/
│   └── dbt.log
│
└── dbt_project/
    │
    ├── dbt_project.yml
    ├── profiles.yml
    ├── .gitignore
    ├── .user.yml
    ├── README.md
    │
    ├── analyses/
    │   ├── .gitkeep
    │   ├── 1_explore.sql
    │   ├── jinja_1.sql
    │   └── macro_1.sql
    │
    ├── macros/
    │   ├── .gitkeep
    │   ├── generate_schema.sql
    │   └── multiply.sql
    │
    ├── models/
    │   │
    │   ├── source/
    │   │   └── sources.yml
    │   │
    │   ├── bronze/
    │   │   ├── bronze_dim_customer.sql
    │   │   ├── bronze_dim_date.sql
    │   │   ├── bronze_dim_product.sql
    │   │   ├── bronze_dim_store.sql
    │   │   ├── bronze_fact_returns.sql
    │   │   ├── bronze_sales.sql
    │   │   └── properties.yml
    │   │
    │   ├── silver/
    │   │   └── silver_salesinfo.sql
    │   │
    │   └── gold/
    │       └── source_gold_items.sql
    │
    ├── seeds/
    │   ├── .gitkeep
    │   └── lookup.csv
    │
    ├── snapshots/
    │   ├── .gitkeep
    │   └── gold_items.yml
    │
    └── tests/
        ├── .gitkeep
        ├── non_negative_test.sql
        │
        └── generic/
            └── generic_non_negative.sql
```

## Project Dependency Flow

The primary transformation flow can be represented as:

```text
                    SOURCE
                      |
       +--------------+--------------+
       |              |              |
       v              v              v
  fact_sales    dim_customer    dim_product
       |              |              |
       v              |              |
 bronze_sales         |              |
       |              |              |
       +--------------+--------------+
                      |
                      v
             silver_salesinfo
                      |
                      v
                   SILVER


                    SOURCE
                      |
                      v
                    items
                      |
                      v
             Deduplication using
                ROW_NUMBER()
                      |
                      v
             source_gold_items
                      |
                      v
                  GOLD
                      |
                      v
                 Snapshot
```

## Useful dbt Commands

Navigate to the dbt project:

```bash
cd dbt_project
```

### Check dbt Version

```bash
dbt --version
```

### Validate Connection

```bash
dbt debug
```

### Install Dependencies

```bash
dbt deps
```

### Load Seeds

```bash
dbt seed
```

### Compile SQL

```bash
dbt compile
```

### Run All Models

```bash
dbt run
```

### Run Tests

```bash
dbt test
```

### Run Models and Tests

```bash
dbt build
```

### Run a Specific Model

```bash
dbt run --select bronze_sales
```

### Run a Specific Layer

```bash
dbt run --select bronze
```

### Run a Model and Its Dependencies

```bash
dbt run --select +silver_salesinfo
```

### Run a Snapshot

```bash
dbt snapshot
```

## Key dbt Concepts Demonstrated

This project provides hands-on examples of several important dbt concepts:

```text
Sources
   |
   v
Models
   |
   v
ref() Dependencies
   |
   v
Jinja + Macros
   |
   v
Testing
   |
   v
Seeds
   |
   v
Snapshots
   |
   v
Databricks
```

### Concepts Covered

* dbt project structure
* dbt profiles
* Databricks adapter
* Sources
* `source()`
* `ref()`
* Model materializations
* Bronze/Silver/Gold architecture
* Jinja templating
* Custom macros
* Built-in tests
* Generic tests
* Singular tests
* Accepted-value validation
* Seeds
* Snapshots
* Deduplication
* Window functions
* SQL transformations
* Schema configuration
* Development and production targets

## Learning Objectives

After working through this project, you should have practical exposure to:

1. Creating and configuring a dbt project.
2. Connecting dbt with Databricks.
3. Defining source tables.
4. Building dependent transformation models.
5. Structuring transformations using Bronze, Silver and Gold layers.
6. Using `source()` and `ref()` correctly.
7. Writing reusable Jinja macros.
8. Creating custom generic tests.
9. Applying built-in dbt tests.
10. Loading static reference data using seeds.
11. Capturing historical changes using snapshots.
12. Building maintainable SQL transformation pipelines.

## Security Considerations

Do not commit production credentials, access tokens, passwords, or other secrets to Git.

The following value in `profiles.yml` is intentionally a placeholder:

```text
YOUR_DATABRICKS_TOKEN
```

For production usage, use secure credential management and environment-specific configuration.

## Future Enhancements

Possible extensions to this project include:

* Add `schema.yml` documentation for every model.
* Add model descriptions and column-level documentation.
* Add source freshness checks.
* Add more comprehensive data quality tests.
* Add incremental models.
* Add CI/CD using GitHub Actions.
* Add dbt documentation generation.
* Add model-level and source-level tests.
* Add exposures and metrics.
* Add automated deployment between development and production.
* Add data lineage documentation.
* Add additional business-facing Gold models.

## Author

**Vishva Prasath**

Data Engineering project demonstrating dbt, Databricks, SQL transformation, data quality, and analytics engineering concepts.
