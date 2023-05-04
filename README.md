[![Continuous integration](https://github.com/solectrus/senec-importer/actions/workflows/push.yml/badge.svg)](https://github.com/solectrus/senec-importer/actions/workflows/push.yml)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/0fd4e23c-13b0-43a6-bfe0-2f235cbe9785.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/0fd4e23c-13b0-43a6-bfe0-2f235cbe9785)

# SENEC importer

Import CSV data downloaded from mein-senec.de and push it to InfluxDB.

## Requirements

- SOLECTRUS installed and running
- CSV files downloaded from mein-senec.de

## Usage

- Login to your host machine where SOLECTRUS is running
- CD into the folder where the .env of SOLECTRUS file is located
- Create a folder `csv` and put the CSV files into it (subfolders allowed)
- Run the following command:

```bash
docker run -it --rm \
           --env-file .env \
           --mount type=bind,source="$PWD/csv",target=/data,readonly \
           --network=solectrus_default \
           ghcr.io/solectrus/senec-importer
```

(Name of the network may vary, see `docker network ls`)

This imports all CSV files from the folder `./csv` (it uses $PWD because Docker requires an absolute path here) and pushes them to your InfluxDB.
The process is idempotent, so you can run it multiple times without any harm.

First Note: If the import is performed after SOLECTRUS has already been used, caching issues may occur, meaning that older periods will not be displayed. In this case, the Redis cache must be flushed once after the import:

```bash
docker exec -it solectrus-redis-1 redis-cli FLUSHALL
```

(Name of the Redis container may vary, see `docker ps`)

Second note: Check the `.env` variable `INSTALLATION_DATE`. This must be set to the day your PV system was installed.

## ENV variables

| Variable                               | Description                                     | Default |
| -------------------------------------- | ----------------------------------------------- | ------- |
| `INFLUX_HOST`                          | Hostname of InfluxDB                            |         |
| `INFLUX_SCHEMA`                        | Schema (http/https) of InfluxDB                 | `http`  |
| `INFLUX_PORT`                          | Port of InfluxDB                                | `8086`  |
| `INFLUX_TOKEN_WRITE` or `INFLUX_TOKEN` | Token for InfluxDB (requires write permissions) |         |
| `INFLUX_ORG`                           | Organization for InfluxDB                       |         |
| `INFLUX_BUCKET`                        | Bucket for InfluxDB                             |         |
| `INFLUX_OPEN_TIMEOUT`                  | Timeout for InfluxDB connection (in seconds)    | `30`    |
| `INFLUX_READ_TIMEOUT`                  | Timeout for InfluxDB read (in seconds)          | `30`    |
| `INFLUX_WRITE_TIMEOUT`                 | Timeout for InfluxDB write (in seconds)         | `30`    |
| `IMPORT_FOLDER`                        | Folder where CSV files are located              | `/data` |
| `IMPORT_PAUSE`                         | Pause after each imported file (in seconds)     | `0`     |

## Dealing with missing wallbox measurements

The CSV data from mein-senec.de is not complete, there are no measurements for the wallbox. To get around this, wallbox charges are **estimated** using the following formula:

```
wallbox_charge_power =   inverter_power (Stromerzeugung)
                       + grid_power_plus (Netzbezug)
                       + bat_power_minus (Akkuentnahme)
                       - grid_power_minus (Netzeinspeisung)
                       - house_power (Stromverbrauch)
                       - bat_power_plus (Akkubeladung)
```

Please note that this method appears to be ineffective for processing CSV files that were created from July 2022 onwards. This is because wallbox charges are now being included in the overall house consumption since that time. Therefore, it seems that there is currently no way to import wallbox measurements.

The [senec-collector](https://github.com/solectrus/senec-collector) does not have this problem, as it obtains the wallbox measurements directly.

## License

Copyright (c) 2020-2023 Georg Ledermann, released under the MIT License
