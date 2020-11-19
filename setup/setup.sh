#!/bin/sh

KIBANA_URL=kibana:5601
PATH_TO_STATE=".status.overall.state"
TARGET_STATE="green"
SECONDS_TO_WAIT=3600 # 60 min 
SECONDS_BETWEEN_CHECKS=30
VERBOSE=true
KIBANA_SAVED_OBJECTS_FOLDER="/kibana-saved-objects"

# Wait until Kibana is ready (overall state is "green")
$VERBOSE && printf "Waiting for Kibana..."
counter=0
until [ "$(curl -s -f $KIBANA_URL/api/status | jq -r $PATH_TO_STATE)" == "$TARGET_STATE" ]; do
  if [ $counter -gt $SECONDS_TO_WAIT ]; then
    echo "Kibana not detected after $SECONDS_TO_WAIT seconds; giving up."
    exit 1
  fi
  $VERBOSE && printf "."
  sleep $SECONDS_BETWEEN_CHECKS
  counter=$((counter+SECONDS_BETWEEN_CHECKS))
done
$VERBOSE && printf "\nKibana is up\n"

# Import saved objects (sorted by filename)
$VERBOSE && echo "Importing saved objects to Kibana..."
ls $KIBANA_SAVED_OBJECTS_FOLDER/*.ndjson | sort -n | while read filename; do
  $VERBOSE && echo "Importing $filename"
  curl -s -f -H 'kbn-xsrf: true' -F file=@"$filename" kibana:5601/api/saved_objects/_import?overwrite=true
  printf '\n'
done

$VERBOSE && echo "Setup complete"
exit 0