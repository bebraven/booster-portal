#!/bin/zsh

rm -rf latest.dump*
./docker-compose/scripts/dblatest_download.sh
./docker-compose/scripts/db_gensqldump.sh

docker-compose down
docker volume rm canvas-lms_canvas-db
docker-compose up -d
sleep 5   # give it a chance to come up
docker-compose exec canvasweb bundle exec rake db:create 

./docker-compose/scripts/dblatest_restore.sh
./docker-compose/scripts/dblatest_restore.sh  # the first time has a couple of errors.
docker-compose down
docker-compose up -d
