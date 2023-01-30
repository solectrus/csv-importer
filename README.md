[![Continuous integration](https://github.com/solectrus/senec-importer/actions/workflows/push.yml/badge.svg)](https://github.com/solectrus/senec-importer/actions/workflows/push.yml)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/0fd4e23c-13b0-43a6-bfe0-2f235cbe9785.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/0fd4e23c-13b0-43a6-bfe0-2f235cbe9785)

# SENEC importer

Import CSV data downloaded from mein-senec.de and push it to InfluxDB.

## Requirements

- CSV files downloaded from mein-senec.de
- Connection to your InfluxDB
- Docker

## Usage

Prepare an `.env` file (like `.env.example`) and place CSV files into a folder of your choice. Then do:

```bash
docker run -it --rm \
           --env-file .env \
           -v /folder/with/csv-files:/data \
           ghcr.io/solectrus/senec-importer
```

This imports all CSV files from the folder `/folder/with/csv-files` and pushes them to your InfluxDB.
The process is idempotent, so you can run it multiple times without any harm.

## License

Copyright (c) 2020-2023 Georg Ledermann, released under the MIT License
