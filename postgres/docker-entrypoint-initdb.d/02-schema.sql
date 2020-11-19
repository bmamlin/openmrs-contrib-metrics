\c openmrs_metrics
CREATE TABLE github (
  id   BIGSERIAL PRIMARY KEY,
  data jsonb NOT NULL,
  metrics jsonb,
  type TEXT GENERATED ALWAYS AS (data->>'type') STORED,
  actor TEXT GENERATED ALWAYS AS (data->'actor'->>'login') STORED,
  owner TEXT GENERATED ALWAYS AS (reverse(split_part(reverse(data->'repo'->>'url'),'/',2))) STORED,
  org TEXT GENERATED ALWAYS AS (data->'org'->>'login') STORED,
  repo TEXT GENERATED ALWAYS AS (reverse(split_part(reverse(data->'repo'->>'url'),'/',1))) STORED,
  repo_url TEXT GENERATED ALWAYS AS (data->'repo'->>'url') STORED,
  created_at TEXT GENERATED ALWAYS AS (data->>'created_at') STORED
);
CREATE INDEX idx_type ON github (type);
CREATE INDEX idx_actor ON github (actor);
CREATE INDEX idx_owner ON github (owner);
CREATE INDEX idx_org ON github (org);
CREATE INDEX idx_repo ON github (repo);