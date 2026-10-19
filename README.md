# Athena Infra

* Setup terraform infrastructure to setup infrastructure for athena

* Infra
    * s3 buckets contiaining table
    * glue databases using medalion architecture
    * cost alerting to not go past £50
    * each athena query should not go above £0.50


## Terraform

```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

terraform init
terraform validate
terraform plan
terraform apply
```

## DBT

* benefits of using dbt: https://aws.amazon.com/blogs/big-data/from-data-lakes-to-insights-dbt-adapter-for-amazon-athena-now-supported-in-dbt-cloud/

```
pip install dbt-core dbt-athena-community
dbt init
dbt run
dbt test

# To generate and serve docs
dbt docs generate
dbt docs serve
```

## Process
* Setup infra
* Investigate data in notebook with polars
* For bronze data add glue table with terraform (using yaml)
* Investigate data with athena
* Use DBT athena connector to transform data to silver

