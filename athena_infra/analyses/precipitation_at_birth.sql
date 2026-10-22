with 

kerala_stations as (
select * from {{ ref('datalake_silver', 'ghcnd_stations')}}
where 
country_code = 'IN'
and latitude < 12.5 and longitude < 77
order by station_name desc
),

prcp_at_indian_stations as (
SELECT *
FROM {{ref('datalake_bronze', 'noaa_ghcn_daily')}}
WHERE year = 2001
  AND element = 'PRCP'
  AND "date" = '20010705'
  AND id like 'IN%'
)

select * from 
prcp_at_indian_stations p inner join kerala_stations k on p.id = k.station_id


