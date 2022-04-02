# SENEC importer

Import CSV data downloaded from mein-senec.de and push it to InfluxDB.


## Requirements

- CSV files downloaded from mein-senec.de
- Connection to your InfluxDB
- Docker


## Usage

Prepare an `.env` file (like `.env.example`) and place CSV files into a folder of your choice. Then do:

```bash
docker run -it \
           --env-file .env \
           -v /folder/with/csv-files:/data \
           ghcr.io/solectrus/senec-importer
```

This imports all CSV files from the folder `/folder/with/csv-files` and pushes them to your InfluxDB.
The process is idempotent, so you can run it multiple times without any harm.


## License

Copyright (c) 2020-2022 Georg Ledermann, released under the MIT License
