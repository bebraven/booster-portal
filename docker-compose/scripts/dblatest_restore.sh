#!/bin/bash
echo "Refreshing your local dev database from the latest Heroku snapshot db"

docker-compose exec canvasdb pg_restore --verbose --clean --jobs 6 --no-acl --no-owner -U canvas -d canvas /latest.dump
