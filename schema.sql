CREATE TABLE users (
  id        serial PRIMARY KEY,
  user_name text
);

CREATE TABLE sites (
  id         serial PRIMARY KEY,
  site_name  text NOT NULL
);

CREATE TABLE sites_users (
  id        serial PRIMARY KEY,
  site_id   integer REFERENCES sites(id),
  user_id   integer REFERENCES users(id) ON DELETE CASCADE
);
