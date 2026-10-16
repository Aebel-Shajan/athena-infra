# Athena Infra

* Setup terraform infrastructure to setup infrastructure for athena

* Infra
    * s3 buckets contiaining table
    * glue databases using medalion architecture
    * cost alerting to not go past £50
    * each athena query should not go above £0.50


## Setup 

```
brew tap hashicorp/tap
```

```
brew install hashicorp/tap/terraform
```