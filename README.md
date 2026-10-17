# Athena Infra

* Setup terraform infrastructure to setup infrastructure for athena

* Infra
    * s3 buckets contiaining table
    * glue databases using medalion architecture
    * cost alerting to not go past £50
    * each athena query should not go above £0.50


## Setup 

0. Install terraform
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

1. Init terraform
```
terraform init
```

2. Validate
```
terraform validate
```

3. Plan
```
terraform plan
```

4. Apply
```
terraform apply
```


## Process
* Setup infra
* Investigate data in notebook with polars
* For bronze data add glue table with terraform (using yaml)
* Investigate data with athena
* Use DBT athena connector to transform data to silver

