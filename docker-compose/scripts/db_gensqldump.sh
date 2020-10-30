#!/bin/bash
echo "Restoring binary dump to database..."
docker-compose down
docker volume rm canvas-lms_canvas-db
docker-compose up -d canvasdb
sleep 5

docker-compose exec canvasdb pg_restore --clean --jobs 2 --no-acl --no-owner -U canvas -d canvas latest.dump
docker-compose exec canvasdb pg_restore --clean --jobs 2 --no-acl --no-owner -U canvas -d canvas latest.dump
echo "Recreating database snapshot with a SQL dump..."
docker-compose exec canvasdb pg_dump --clean -U canvas canvas > latest-tmp.sql

echo "Replacing production URLs with dev URLs...piping to database"
cat latest-tmp.sql | sed -e "

  s/https:\/\/sso.bebraven.org/http:\/\/platformweb:3020\/cas/g;
  s/https:\/\/platform.bebraven.org/http:\/\/platformweb:3020/g;
  s/https:\/\/join.bebraven.org/http:\/\/joinweb:3001/g;

  # Also fix up internal links in assignments to stay on staging as we navigate
  s/https:\/\/portal.bebraven.org/http:\/\/canvasweb:3000/g;

  # If we have links to the kits from the LC playbook, fix that up.
  s/https:\/\/kits.bebraven.org/http:\/\/kitsweb:3005/g;

  # Also fix up links to custom CSS/JS. Note: we could do this on this row but it's a pain
  # select id, name, settings from accounts where id = 1;
  s/https:\/\/s3.amazonaws.com\/canvas-stag-assets/http:\/\/cssjsweb:3004/g;

" > latest.sql

rm -f latest-tmp.sql
