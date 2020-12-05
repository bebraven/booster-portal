#!/bin/bash
echo "Refreshing your local dev database from the staging db"
 
app=${1:-portal-bebraven-dot-org}
backupid=${2:-}
./docker-compose/scripts/dblatest_download.sh $app $backupid &&
./docker-compose/scripts/db_gensqldump.sh &&
./docker-compose/scripts/dblatest_restore.sh
