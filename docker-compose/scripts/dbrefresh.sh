#!/bin/bash
echo "Refreshing your local dev database from the staging db"
 
app=${1:-portal-bebraven-dot-org}
./docker-compose/scripts/dblatest_download.sh $app &&
./docker-compose/scripts/db_gensqldump.sh &&
./docker-compose/scripts/dblatest_restore.sh
