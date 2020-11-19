FROM postgres:13

RUN apt-get update && \
  apt-get install -y jq

COPY ./docker-entrypoint-initdb.d /docker-entrypoint-initdb.d