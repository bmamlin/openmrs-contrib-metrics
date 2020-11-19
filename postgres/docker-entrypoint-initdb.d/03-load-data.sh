#!/bin/sh

for filename in /data/*.json.gz
do
  printf "Importing data from $filename..."
  zcat "$filename" \
  | jq -rc '.payload |= fromjson | (.other // empty) |= fromjson' \
  | sed 's/\\/\\\\/g' \
  | psql -U postgres openmrs_metrics -c "copy github (data) from stdin;"
done