#!/bin/bash
echo "Piping latest.sql to database"
echo "DROP SCHEMA public CASCADE;" | docker-compose exec -T canvasdb psql -U canvas -d canvas
echo "CREATE SCHEMA public;" | docker-compose exec -T canvasdb psql -U canvas -d canvas
cat latest.sql | docker-compose exec -T canvasdb psql -U canvas -d canvas

echo "Do unknown fancy stuff for dev env..."
# Adjust some settings for dev
# - Set the dev encryption key hash so that dev passwords are encrypted using a dev value.
# - Set the dev access token and access token hint, used for other apps to be able to call into the Canvas API.
# - Make the timeout to wait for the SSO server 15 seconds since dev can be slow, especially on first start.
# - Disable Canvas analytics which relies on a Cassandra DB. No need for this and it clutter the error log.
cat <<EOF | docker-compose exec -T canvasdb psql -U canvas -d canvas

  -- This is the hashed value of the dev only encryption key used in security.yml
  update settings set value = '40ed0028ef3004ed37cbec550a57bcde82472631' where name = 'encryption_key_hash';

  -- The 'Beyond Z Platform Integration' access token for dev is:
  -- BEW8ldtbMypKZiCs8EmW2eQXfOoBpfOEwNJXwyvfIKZIpMgQzBfYUugc4V20oFgt
  -- These are the encrypted values that the above accces token works against:
  update access_tokens set crypted_token = 'd3cb10787c10be0c15bd036f1ae502360e4cc7c4', token_hint = 'BEW8l' where id = 2;

  insert into settings (name, value, created_at, updated_at)
  select 'cas_timelimit', '15', NOW(), NOW()
  where not exists (select id from settings where name = 'cas_timelimit');

  delete from settings where name = 'enable_page_views';
EOF
