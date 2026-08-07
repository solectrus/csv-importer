[![Continuous integration](https://github.com/solectrus/csv-importer/actions/workflows/push.yml/badge.svg)](https://github.com/solectrus/csv-importer/actions/workflows/push.yml)
[![Maintainability](https://qlty.sh/gh/solectrus/projects/csv-importer/maintainability.svg)](https://qlty.sh/gh/solectrus/projects/csv-importer)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/ccfef5d1-6717-4411-9895-69dc32ad5c91.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/ccfef5d1-6717-4411-9895-69dc32ad5c91)
[![Code Coverage](https://qlty.sh/gh/solectrus/projects/csv-importer/coverage.svg)](https://qlty.sh/gh/solectrus/projects/csv-importer)

# CSV importer

Import CSV with photovoltaic data and push it to InfluxDB for use with SOLECTRUS.

## Requirements

- SOLECTRUS installed and running
- CSV files in one of the supported formats (see below)

## Supported formats

The format is detected automatically from the first line of each file, so you can mix formats in one run.

- **SENEC** — exported from mein-senec.de, one row per reading
- **Sungrow** — exported from portaleu.isolarcloud.com, one row per reading
- **SolarEdge** — exported from monitoring.solaredge.com, one row per day, which the importer spreads over 288 points of 5 minutes each (see [details in the wiki](https://github.com/solectrus/csv-importer/wiki/SolarEdge))

Not every format carries every sensor:

| Sensor                    |   SENEC    | Sungrow | SolarEdge  |
| ------------------------- | :--------: | :-----: | :--------: |
| Inverter power            |     ✓      |    ✓    |     ✓      |
| House power               |     ✓      |    ✓    | calculated |
| Grid import power         |     ✓      |    ✓    |     ✓      |
| Grid export power         |     ✓      |    ✓    |     ✓      |
| Battery charging power    |     ✓      |    ✓    |     –      |
| Battery discharging power |     ✓      |    ✓    |     –      |
| Battery state of charge   | if present |    –    |     –      |

SolarEdge exports no house reading, so the importer calculates it: what the inverter made, plus what came from the grid, less what went to it.

## Usage with HELIOS (recommended)

[HELIOS](https://github.com/solectrus/helios), the web-based control panel for SOLECTRUS, runs this importer for you. No shell, no `docker run`, no manual cleanup:

- Open HELIOS and go to **Data sources → Import historical data**
- Upload your CSV files, either a single `.csv` or a `.zip` archive of them (subfolders allowed)
- Start the import and watch its progress

HELIOS pulls the importer image, passes the InfluxDB credentials and the sensor mapping from your live `.env`, and afterwards flushes the Redis cache and resets the daily summaries — the two manual steps described below.

Not running HELIOS yet? You can add it to a SOLECTRUS installation that is already up. HELIOS reads the existing `compose.yaml` and `.env`, keeps your configuration and preserves anything it does not understand, so nothing has to be set up a second time. One command installs it, see [solectrus.de/install](https://solectrus.de/install/en/).

## Usage without HELIOS

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

**Important note:** A second step is required: You must reset the “Daily summaries” (via “Settings” in the dashboard after you have logged in as admin).

## Configuration

The following environment variables can be used to configure the importer. Variables marked **required** have no default; the importer refuses to start without a usable InfluxDB URL.

| Variable                                  | Description                                                   | Default                  |
| ----------------------------------------- | ------------------------------------------------------------- | ------------------------ |
| `INFLUX_HOST`                             | Hostname of InfluxDB (**required**)                           |                          |
| `INFLUX_SCHEMA`                           | Schema (http/https) of InfluxDB                               | `http`                   |
| `INFLUX_PORT`                             | Port of InfluxDB                                              | `8086`                   |
| `INFLUX_TOKEN_WRITE` or `INFLUX_TOKEN`    | Token for InfluxDB, requires write permissions (**required**) |                          |
| `INFLUX_ORG`                              | Organization for InfluxDB (**required**)                      |                          |
| `INFLUX_BUCKET`                           | Bucket for InfluxDB (**required**)                            |                          |
| `INFLUX_OPEN_TIMEOUT`                     | Timeout for InfluxDB connection (in seconds)                  | `30`                     |
| `INFLUX_READ_TIMEOUT`                     | Timeout for InfluxDB read (in seconds)                        | `60`                     |
| `INFLUX_WRITE_TIMEOUT`                    | Timeout for InfluxDB write (in seconds)                       | `30`                     |
| `INFLUX_SENSOR_INVERTER_POWER`            | Measurement/field for inverter power                          | `SENEC:inverter_power`   |
| `INFLUX_SENSOR_HOUSE_POWER`               | Measurement/field for house power                             | `SENEC:house_power`      |
| `INFLUX_SENSOR_GRID_IMPORT_POWER`         | Measurement/field for grid import power                       | `SENEC:grid_power_plus`  |
| `INFLUX_SENSOR_GRID_EXPORT_POWER`         | Measurement/field for grid export power                       | `SENEC:grid_power_minus` |
| `INFLUX_SENSOR_BATTERY_CHARGING_POWER`    | Measurement/field for battery charge power                    | `SENEC:bat_power_plus`   |
| `INFLUX_SENSOR_BATTERY_DISCHARGING_POWER` | Measurement/field for battery discharge power                 | `SENEC:bat_power_minus`  |
| `INFLUX_SENSOR_BATTERY_SOC`               | Measurement/field for battery state of charge                 | `SENEC:bat_fuel_charge`  |
| `SENEC_IGNORE`                            | SENEC only: field names to skip (comma-separated)             |                          |
| `IMPORT_FOLDER`                           | Folder where CSV files are located                            | `/data`                  |
| `IMPORT_PAUSE`                            | Pause after each imported file (in seconds)                   | `0`                      |
| `TZ`                                      | Time zone to use when parsing times                           | `Europe/Berlin`          |

The sensor variables follow the SOLECTRUS convention `MEASUREMENT:field`. Use the same values your dashboard reads, otherwise the imported points land somewhere it does not look.

`SENEC_IGNORE` lists field names, the part after the colon. For example, `SENEC_IGNORE=bat_fuel_charge,bat_power_plus` skips the battery state of charge and the battery charge power of SENEC files.

## Development

Ruby 4.0 (see `.ruby-version`) is all you need, no services:

```bash
bundle install
bundle exec rspec        # tests, coverage gates at 100% line and branch
bundle exec rubocop      # linter
```

Adding a vendor format means adding one adapter in `app/adapters/` and a real sample export in `spec/data/`. See [AGENTS.md](AGENTS.md) for the contract an adapter has to fulfill.

## License

Copyright (c) 2020-2026 Georg Ledermann, released under the MIT License

Many thanks to these incredible people for improving this project:

- Sascha Böck (https://github.com/AlpenFlizzer) for SolarEdge support
- Rainer Drexler (https://github.com/holiday-sunrise) for Sungrow support
- Sebastian Löb (https://github.com/loebse) for bug fixes
