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

ALTER TABLE users
      RENAME COLUMN name TO user_name;

ALTER TABLE sites_users
      RENAME COLUMN users_id TO user_id;

SELECT site_name, user_name FROM sites
  INNER JOIN sites_users ON sites.id = sites_users.site_id
  INNER JOIN users ON sites_users.user_id = users.id;


Subquery


-- ************************************************************

INSERT INTO users (name) VALUES ('Medley');
INSERT INTO users (name) VALUES ('Bodine');


INSERT INTO sites (site_name, user_ids) VALUES ('http://www.google.com', '{1}');
INSERT INTO sites (site_name, user_ids) VALUES ('http://www.yahoo.com', '{13}');

UPDATE sites SET user_ids = array_append(user_ids, 5) WHERE site_name = 'http://www.google.com';
UPDATE sites SET user_ids = array_append(user_ids, 7);

UPDATE sites SET user_ids = array_remove(user_ids, 5);
UPDATE sites SET user_ids = array_remove(user_ids, 5) WHERE site_name = 'http://www.google.com';

-- For deleting an account
UPDATE sites SET user_ids = array_remove(user_ids, $1);
DELETE FROM sites WHERE user_ids = '{}';

SELECT site_name FROM sites;
SELECT site_name FROM sites WHERE site_name = 'http://www.google.com';
SELECT site_name FROM sites WHERE site_name = 'http://www.rei.com';

SELECT 11 = ANY ('{1,2,3}'::int[]);

SELECT 1 FROM sites WHERE val = ANY (user_ids);



1) Adding website to a user list:

-- Check if website already exists in sites TABLE

if exists
  if user id is already in the user_ids array for this user
    nothing
  else
    append user id to sites.user_ids array_append for this user
  end
else
  insert new site row with values for website and user id (array with one element)
end

2) Displaying all websites for a user:

SELECT site_name FROM sites WHERE user id is in users_id array;




Implementation for adding a website to a user list

SELECT site_name, user_ids FROM sites WHERE site_name = 'http://www.google.com';

if the row then exists

elsif 0 rows then does not exist


@@@@@@@@@

ALTER TABLE sites ADD COLUMN last_login timestamp
                 NOT NULL
                 DEFAULT NOW();