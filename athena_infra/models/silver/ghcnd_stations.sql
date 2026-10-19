-- Parses the fixed width ghcnd-stations.txt, column positions from the "FORMAT OF ghcnd-stations.txt" section of
-- s3://noaa-ghcn-pds/readme.txt
with raw as (
    select line
    from {{ source('bronze', 'ghcnd_stations_raw') }}
    where trim(line) <> ''
),

parsed as (
    select
        trim(substr(line, 1, 11))  as station_id,
        trim(substr(line, 13, 8))  as latitude,
        trim(substr(line, 22, 9))  as longitude,
        trim(substr(line, 32, 6))  as elevation,
        trim(substr(line, 39, 2))  as state,
        trim(substr(line, 42, 30)) as station_name,
        trim(substr(line, 73, 3))  as gsn_flag,
        trim(substr(line, 77, 3))  as hcn_crn_flag,
        trim(substr(line, 81, 5))  as wmo_id
    from raw
)

select
    station_id,
    -- First 2 chars of the id are the FIPS country code, 3rd is the network code
    substr(station_id, 1, 2)                                  as country_code,
    substr(station_id, 3, 1)                                  as network_code,
    station_name,
    cast(latitude as double)                                  as latitude,
    cast(longitude as double)                                 as longitude,
    -- -999.9 means missing elevation
    nullif(cast(elevation as double), -999.9)                 as elevation_m,
    nullif(state, '')                                         as state,
    gsn_flag = 'GSN'                                          as is_gsn,
    case hcn_crn_flag when 'HCN' then 'HCN' when 'CRN' then 'CRN' end as hcn_crn_flag,
    nullif(wmo_id, '')                                        as wmo_id
from parsed
