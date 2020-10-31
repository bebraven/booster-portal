#!/bin/zsh

app=${1:-portal-bebraven-dot-org}
./docker-compose/scripts/dbrefresh.sh $app
./docker-compose/scripts/restart.sh
