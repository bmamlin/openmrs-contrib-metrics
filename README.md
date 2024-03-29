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
AND (
	repo.name IN (
		SELECT name FROM `openmrs-github-stats.openmrs_events.openmrs-repos`
	)
  OR LOWER(repo.name) like '%openmrs%'
  OR org.login='openmrs'
)
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
- Only events for public repositories under the OpenMRS organization, with 
  "openmrs" in the repository name, or that have been manually collected and their
  name included in the `openmrs-repos` table within our BigQuery project are
  included. OpenMRS-related work in GitHub outside of the OpenMRS organization within
  repositories that do _not_ have "openmrs" in the name and have not been manually
  added to the `openmrs-repos` table in BigQuery are not included in these stats.
  This means, for example, work in Micro Frontend repositories (which chose
  to use a naming convention that does not include "openmrs") outside of the
  OpenMRS organization (e.g., by other organizations or in personal forks) are not
  included unless we manually include them by grepping them from a GitHub
  web search (see details [here](https://talk.openmrs.org/t/2021-community-contribution-stats-by-quarter/35772/9?u=burke)).

## Requirements

- Docker (with [docker-compose](https://docs.docker.com/compose/install/))
- 6+ GB of memory available
- Sufficient virtual memory for Docker (`sysctl -w vm.max_map_count=262144`)

**NOTE**: if you try running this stack and elasticsearch containers are exiting with
error code 137, it is because they are running out of memory. If you want, you can monitor
Docker memory usage from a terminal with `docker ps -q | xargs docker stats --no-stream`

## Running the stack

1. Clone this repository (`git clone https://github.com/bmamlin/openmrs-contrib-metrics`)
2. Within the `github-data` folder, run `./download-data.sh` to download data files
3. In the top folder, run `docker-compose up -d`
4. Wait for Kibana to show up at http://localhost:5601/
5. Once the data have loaded (set date filter to last 15 years – back to at least 2014 – and 
   open visualization "Event Counts" to see total number of events loaded... 2014-2022 includes 
   532,944 events), you'll need to manually add the filter for bots.

## Manually adding "NOT bot" filter to exclude bots

Unfortunately, Kibana doesn't provide a way to export/save filters, so you will need to manually 
introduce the filter to exclude bots. The easiest way to do this is to navigate to the dashboard,
remove any parameters from the URL (i.e., anything following a question mark and the question mark),
and then paste the following parameters to the end of the URL in the browser's address bar:

```
?_g=(filters:!(('$state':(store:globalState),meta:(alias:bot,disabled:!f,index:'c81b8f30-9848-11ed-883c-8984dc663080',key:actor.keyword,negate:!t,params:!(openmrs-bot,codecov%5Bbot%5D,dependabot%5Bbot%5D,dependabot-preview%5Bbot%5D,github-actions%5Bbot%5D,codacy-bot,pihinformatics,pull%5Bbot%5D,renovate%5Bbot%5D,transifex-integration%5Bbot%5D,whitesource-bolt-for-github%5Bbot%5D),type:phrases),query:(bool:(minimum_should_match:1,should:!((match_phrase:(actor.keyword:openmrs-bot)),(match_phrase:(actor.keyword:codecov%5Bbot%5D)),(match_phrase:(actor.keyword:dependabot%5Bbot%5D)),(match_phrase:(actor.keyword:dependabot-preview%5Bbot%5D)),(match_phrase:(actor.keyword:github-actions%5Bbot%5D)),(match_phrase:(actor.keyword:codacy-bot)),(match_phrase:(actor.keyword:pihinformatics)),(match_phrase:(actor.keyword:pull%5Bbot%5D)),(match_phrase:(actor.keyword:renovate%5Bbot%5D)),(match_phrase:(actor.keyword:transifex-integration%5Bbot%5D)),(match_phrase:(actor.keyword:whitesource-bolt-for-github%5Bbot%5D))))))),refreshInterval:(pause:!t,value:0),time:(from:now-8y,to:now))
```

Adding the above gibberish as the parameter portion of the URL should add a <kbd>NOT bot</kbd> filter 
to the view. You want to click on this filter and pin it if it is not already pinned. This will apply 
the bot filter by default to the dashboard and any visualations are queries you view (since we want to 
ignore bot activity for most views).

### Manual installation from scratch

If you are new to git & Docker and are manually installing everything from scratch
instead of using a machine pre-configured with git & Docker (like Digital Ocean provides for 
droplets in its marketplace), reviewing [this issue](https://github.com/bmamlin/openmrs-contrib-metrics/issues/1#issue-785815236) 
might save you some time.

### Tips on running the stack

* On a machine with 8 GB of memory and 4 CPUs, it takes about 10 minutes to before
all data are visible within Kibana.
* When the stack is first built in a debian environment, you may see a 
warning message like "debconf: delaying package configuration, since apt-utils 
is not installed" (e.g., when the postgres image is being initially built). This 
warning can safely be ignored.
* When browsing visualizations, be sure to set your date filter to something like
"Last 15 years" to ensure you are seeing all data (it goes back to 2014). The 
default may be set to "15 minutes", in which case you won't see any data.

## Stopping temporarily

`docker-compose pause`

(start back up with `docker-compose unpause`)

## Restarting

`docker-compose up -d`

## Stopping & cleaning up

Shut down the docker containers and clear elasticsearch volumes:

`docker-compose down -v`

Purge the postgres data:

`rm -rf pgdata`

## Reloading data

If you download new data or make changes to github files, you must clear the
`pgdata` subfolder (`rm -rf pgdata`) for data to get reloaded. If the `pgdata` 
folder contains _any_ data, postgres will not try to load any new data.

## Troubleshooting

### Stack fails to run

If the stack fails to run, check the logs with:

`docker-compose logs`

If you see error message or messages of services being unreachable, scroll to 
where the errors begin. If you see a message like "max virtual memory areas 
vm.max_map_count [65530] is too low, increase to at least [262144]", then 
increase virtual memory with:

`sysctl -w vm.max_map_count=262144`

To make the change permanent, you need to edit `/etc/sysctl.conf` and set 
`vm.max_map_count` to 262144 (from [stackoverflow](https://stackoverflow.com/a/51448773/5602641)).

### NOT bot filter not being created properly

If the <kbd>NOT bot</kbd> filter is not rendering as expected, it's possible 
the index pattern's ID has changed. You may notice a UUID (in the form
`c81b8f30-9848-11ed-883c-8984dc663080` in the first part of the "NOT bot"
filter definition. If you navigate to Stack Management > Index Patterns in 
Kibana and select the default `github*` pattern, the UUID in the address 
bar for this index pattern should match the one referenced by the "NOT bot" 
filter. If they don't match, copy the UUID of the index pattern and replace 
the (like outdated) UUID in the "NOT bot" filter definition when adding the 
"NOT bot" filter to the address bar as described above.
