[![Continuous integration](https://github.com/solectrus/csv-importer/actions/workflows/push.yml/badge.svg)](https://github.com/solectrus/csv-importer/actions/workflows/push.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/22651f8e68e4c3123a39/maintainability)](https://codeclimate.com/github/solectrus/csv-importer/maintainability)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/ccfef5d1-6717-4411-9895-69dc32ad5c91.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/ccfef5d1-6717-4411-9895-69dc32ad5c91)
[![Test Coverage](https://api.codeclimate.com/v1/badges/22651f8e68e4c3123a39/test_coverage)](https://codeclimate.com/github/solectrus/csv-importer/test_coverage)

# CSV importer

Import CSV with photovoltaic data and push it to InfluxDB for use with SOLECTRUS.

## Requirements

- SOLECTRUS installed and running
- CSV files in one of the following supported formats:
  - SENEC (downloaded from mein-senec.de)
  - Sungrow (downloaded from portaleu.isolarcloud.com)
  - SolarEdge (downloaded from monitoring.solaredge.com, see [details in the wiki](https://github.com/solectrus/csv-importer/wiki/SolarEdge))

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
           ghcr.io/solectrus/csv-importer
```

(Name of the network may vary, see `docker network ls`)

This imports all CSV files from the folder `./csv` (it uses $PWD because Docker requires an absolute path here) and pushes them to your InfluxDB.
The process is idempotent, so you can run it multiple times without any harm.

### Beware of caching issues

If the import is performed after SOLECTRUS has already been used, caching issues may occur, meaning that older periods will not be displayed. In this case, the Redis cache must be flushed once after the import:

```bash
docker exec -it solectrus-redis-1 redis-cli FLUSHALL
```

(Name of the Redis container may vary, see `docker ps`)

Check the `.env` variable `INSTALLATION_DATE`. This must be set to the day your PV system was installed.

### Configuration

The following environment variables can be used to configure the importer:

| Variable                                | Description                                     | Default                  |
| --------------------------------------- | ----------------------------------------------- | ------------------------ |
| `INFLUX_HOST`                           | Hostname of InfluxDB                            |                          |
| `INFLUX_SCHEMA`                         | Schema (http/https) of InfluxDB                 | `http`                   |
| `INFLUX_PORT`                           | Port of InfluxDB                                | `8086`                   |
| `INFLUX_TOKEN_WRITE` or `INFLUX_TOKEN`  | Token for InfluxDB (requires write permissions) |                          |
| `INFLUX_ORG`                            | Organization for InfluxDB                       |                          |
| `INFLUX_BUCKET`                         | Bucket for InfluxDB                             |                          |
| `INFLUX_OPEN_TIMEOUT`                   | Timeout for InfluxDB connection (in seconds)    | `30`                     |
| `INFLUX_READ_TIMEOUT`                   | Timeout for InfluxDB read (in seconds)          | `30`                     |
| `INFLUX_WRITE_TIMEOUT`                  | Timeout for InfluxDB write (in seconds)         | `30`                     |
| `INFLUX_SENSOR_INVERTER_POWER`          | Measurement/field for inverter power            | `SENEC:inverter_power`   |
| `INFLUX_SENSOR_HOUSE_POWER`             | Measurement/field for house power               | `SENEC:house_power`      |
| `INFLUX_SENSOR_GRID_IMPORT_POWER`       | Measurement/field for grid import power         | `SENEC:grid_power_plus`  |
| `INFLUX_SENSOR_GRID_EXPORT_POWER`       | Measurement/field for grid export power         | `SENEC:grid_power_minus` |
| `INFLUX_SENSOR_BATTERY_CHARGE_POWER`    | Measurement/field for battery charge power      | `SENEC:bat_power_plus`   |
| `INFLUX_SENSOR_BATTERY_DISCHARGE_POWER` | Measurement/field for battery discharge power   | `SENEC:bat_power_minus`  |
| `SENEC_IGNORE`                          | Optionally ignore some fields (comma-separated) |                          |
| `IMPORT_FOLDER`                         | Folder where CSV files are located              | `/data`                  |
| `IMPORT_PAUSE`                          | Pause after each imported file (in seconds)     | `0`                      |
| `TZ`                                    | Time zone to use when parsing times             | `Europe/Berlin`          |

## License

Copyright (c) 2020-2024 Georg Ledermann, released under the MIT License

Many thanks to these incredible people for improving this project:

- Sascha Böck (https://github.com/AlpenFlizzer) for SolarEdge support
- Rainer Drexler (https://github.com/holiday-sunrise) for Sungrow support
- Sebastian Löb (https://github.com/loebse) for bug fixes
