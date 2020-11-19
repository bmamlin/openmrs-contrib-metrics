#!/bin/bash

# Use a tiny little alpine image + curl & jq to run our script
docker run --rm   \
  -v $PWD:/data   \
  -w /data alpine \
  sh -c "apk add --no-cache curl jq > /dev/null; ./wget-from-google-drive.sh"