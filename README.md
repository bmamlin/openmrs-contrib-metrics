# OpenMRS Metrics

An [ELK Stack](https://www.elastic.co/what-is/elk-stack) for OpenMRS community data.

![OpenMRS Metrics](images/openmrs-metrics.png)

## What data?

- GitHub events (commits, pull requests, comments, etc.) since 2014 within the
  OpenMRS organization or any repository with "openmrs" in its name.

## How it works

[GitHub archive](https://www.gharchive.org/) data within
[Google Big Query](https://cloud.google.com/bigquery) are manually extracted using
a query like this:

```sql
SELECT *
FROM `githubarchive.year.*`
WHERE _TABLE_SUFFIX BETWEEN '2020' AND '2020'
AND (repo.name like '%openmrs%' OR org.login='openmrs')
```

These GitHub events by year are extracted as [newline delimited JSON](http://ndjson.org/)
files, [gzipped](https://www.gzip.org/), and stored in Google Drive.

This repository includes an ELK Stack comprising:

- **postgres** stores all the JSON events where key metrics are extracted using
  a [SQL query](postgres/docker-entrypoint-initdb.d/04-metrics.sql)
- **logstash** is used to transfer metrics from postgres into elasticsearch
- **elasticsearch** (cluster of two instances) indexes all of the metrics
- **kibana** provides a user interface for browsing and exploring the data
  within elasticsearch

## Known issues

- Extracting data from the github archive into files for this stack is a manual process
- Data only go back to 2014, because that's how far back the github archive goes
- Only events for public repositories under the OpenMRS organization or with "openmrs" in
  the repository name are included. OpenMRS-related work in GitHub outside of the OpenMRS
  organization within repositories that do _not_ have "openmrs" in the name are not
  included. This means, for example, work in Micro Frontend repositories (which chose
  to use a naming convention that does not include "openmrs") outside of the
  OpenMRS organization (e.g., by other organizations or in personal forks) are not
  included.

## Requirements

- Docker
- Plenty of memory (e.g., 6+ GB allocated to Docker)

**NOTE**: if you try running this stack and elasticsearch containers are exiting with
error code 137, it is because they are running out of memory. If you want, you can monitor
Docker memory usage from a terminal with `docker ps -q | xargs docker stats --no-stream`

## Running the stack

1. Clone this repository
2. Within the `github-data` folder, run `./download-data.sh` to download data files
3. In the top folder, run `docker-compose up -d`
4. Wait for Kibana to show up at http://localhost:5601/

On a machine with 16 GB of memory (6 GB and 3 CPUs allocated to Docker), it takes up
to 10 minutes before Kibana starts working and up to 45 minutes before all data are
available, so be patient. On the other hand, if you create a
[Digital Ocean](https://digitalocean.com) droplet with 64 GB of memory and allocate 4 GB
to each elasticsearch instance and 30 GB to logstash, you can be up and running in 6 minutes
(just don't forget to delete the droplet when done, since it costs \$0.5 USD per minute)

**TIP**: when browsing visualizations, be sure to set your date filter to something like
"Last 10 years" to ensure you are seeing all data. The default may be set to "15
minutes", in which case you won't see any data.

## Stopping temporarily

`docker-compose pause`

(start back up with `docker-compose unpause`)

## Restarting

`docker-compose up -d`

## Stopping & cleaning up

`docker-compose down -v`

If you want to remove all loaded data, then purge the `pgdata` subfolder.

## Reloading data

If you download new data or make changes to github files, you must clear the
`pgdata` subfolder for data to get reloaded. If the `pgdata` folder contains _any_
data, postgres will not try to load any new data.
