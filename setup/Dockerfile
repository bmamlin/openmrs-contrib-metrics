FROM alpine

RUN apk add --no-cache curl jq

VOLUME /kibana-saved-objects

COPY ./setup.sh /usr/local/bin/setup.sh

CMD ["setup.sh"]