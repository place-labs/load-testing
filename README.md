# PWC ME Desk Import

## Usage

1. `shards build`
2. `./bin/import_bookings`
3. `./bin/import_desks`

## Desk Command line switches

* `-d https://path_to_TSV`
* `-u user@name.com`
* `-p password`
* `-d https://placeos.domain`
* `-c abs1234xfndsx` the client app id
* `-s asdfds345543dfg` the client secret


i.e.

```
./bin/import_desks -u support@place.technology -p development -d "https://mysmartoffice-stg.mer.pwc.com" -c "c3c1ebeb60d94dcc96caf5fae12" -s "tvEQghtRLjD0YwbSlls9hiuzGe9Qze4m9cTgn7sn6Ew8g"
```

## Bookings Command line switches

* `-m calendar-module-id`
* `-b booking-driver-id`
* `-u user@name.com`
* `-p password`
* `-d https://placeos.domain`
* `-c abs1234xfndsx` the client app id
* `-s asdfds345543dfg` the client secret


i.e.

```
./bin/import_bookings -u support@place.technology -p development -d "https://mysmartoffice-stg.mer.pwc.com" -c "c3c1ebeb60d94dcc96caf5fae12" -s "tvEQghtRLjD0YwbSlls9hiuzGe9Qze4m9cTgn7sn6Ew8g" -m "mod-FSqCVJUOP48" -b "driver-FTIqL3xTyeD"
```
