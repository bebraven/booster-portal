#!/bin/bash
echo "Downloading the latest Heroku database snapshot"
rm -f latest.dump*

heroku pg:backups:download --app $1 $2 # the argument should identify the heroku app
