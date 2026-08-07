# CSV importer

Plain Ruby CLI that reads photovoltaic CSV exports and writes them to InfluxDB. Runs once in a container and exits.

## Adapters

A vendor format is one file in `app/adapters/`: a `BaseAdapter` subclass with `self.probe?(first_line)`, `self.csv_options` and the column mapping. `CsvProbe` finds it through `BaseAdapter.subclasses` — nothing to register anywhere. A new adapter needs a real sample file in `spec/data/`.

`Config` is a frozen `Data` object. Memoization ivars must be assigned **before** `super` in `initialize`, or the assignment raises.

## Testing

`bundle exec rspec`. No services needed.

- **Coverage gates at 100% line and 100% branch** on a full run. A single-file run skips the gate on purpose. New code needs both sides of every branch covered.
- VCR cassettes match on `method`, `uri` **and** `body`. A changed payload needs `VCR=all bundle exec rspec` to re-record; the `INFLUX_*` secrets are filtered out.
- `spec/data/` holds real vendor exports with their quirks: BOM, CR+CR+LF, kW vs. kWh column names.

## Linting

`bundle exec rubocop --autocorrect` after changing Ruby.

## Docker

`BUNDLE_WITHOUT=development:test` is set at build **and** run time; the two must agree or `bundle exec` fails at start. `RUBY_YJIT_ENABLE=1` is deliberate — the Alpine build ships YJIT off. Benchmark that flag inside the container only: the local shell exports it already, so a local comparison measures nothing.
