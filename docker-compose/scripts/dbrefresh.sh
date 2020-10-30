#!/bin/bash
echo "Refreshing your local dev database from the staging db"
 
./docker-compose/scripts/dblatest_download.sh &&
./docker-compose/scripts/db_gensqldump.sh &&
./docker-compose/scripts/dblatest_restore.sh