#!/bin/zsh

app=${1:-portal-bebraven-dot-org}
backupid=${2:-}
./docker-compose/scripts/dbrefresh.sh $app $backupid
./docker-compose/scripts/restart.sh
