# CSV importer

Plain Ruby CLI that reads photovoltaic CSV exports and writes them to InfluxDB. Runs once in a container and exits.

## Adapters

A vendor format is one file in `app/adapters/`: a `BaseAdapter` subclass that implements

- `self.probe?(first_line)` and `self.csv_options`,
- `initialize(headers, config:)`, which resolves every column **after** `super` through `column` (missing one is a broken file) or `optional_column` (may be absent),
- `time(row)` returning an epoch, and `values(row)` returning a `sensor => value` hash,
- private `sensors`, the sensor names this file delivers.

`BaseAdapter#points` turns those into one point per measurement. Override it only when one row expands into several timestamps, as `SolarEdgeAdapter` does for a daily total.

`CsvProbe` finds the class through `BaseAdapter.subclasses` — nothing to register anywhere. A new adapter needs a real sample file in `spec/data/`.

The sensor names are a closed set: `config.field(:x)` calls `influx_sensor_x` on `Config`, so a name without a matching member raises. An eighth sensor is three edits — a `Config` member, an entry in `Config.sensors_from_env`, and a row in the README table.

`Config` is a frozen `Data` object. Memoization ivars must be assigned **before** `super` in `initialize`, or the assignment raises. Every env var it reads is documented in the README table; keep the two in sync.

## Testing

`bundle exec rspec`. No services needed.

- **Coverage gates at 100% line and 100% branch** on a full run. A single-file run skips the gate on purpose. New code needs both sides of every branch covered.
- VCR cassettes match on `method`, `uri` **and** `body`. A changed payload needs `VCR=all bundle exec rspec` to re-record — and that run does talk to a real InfluxDB, at the `INFLUX_HOST` of `.env.test`. The `INFLUX_*` secrets are filtered out of the cassette.
- `spec/data/` holds real vendor exports with their quirks: BOM, CR+CR+LF, kW vs. kWh column names.

## Linting

`bundle exec rubocop --autocorrect` after changing Ruby.

## Docker

`BUNDLE_WITHOUT=development:test` is set at build **and** run time; the two must agree or `bundle exec` fails at start. The Ruby version is pinned twice, in `.ruby-version` and in both `FROM` lines. `RUBY_YJIT_ENABLE=1` is deliberate — the Alpine build ships YJIT off. Benchmark that flag inside the container only: the local shell exports it already, so a local comparison measures nothing.
