# Load Testing

## Usage

1. `shards build`
2. `./bin/metadata_load`

## Command line switches

* `-u "https://placeos.domain.com"`
* `-a x-api-key`
* `-l 10` number of concurrent requests to be running - defaults to 5
* `-m read_write` read, write, read_write - defaults to read_write
* `-h` help

i.e.

```
./bin/metadata_load -u "https://placeos.domain.com" -a x-api-key -l 5"```
