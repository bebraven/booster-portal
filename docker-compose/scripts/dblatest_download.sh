#!/bin/bash
echo "Downloading the latest Heroku database snapshot"
rm -f latest.dump*

heroku pg:backups:download --app portal-bebraven-dot-org
