#!/bin/bash
name=$(basename `pwd`)
docker build -t $name:$1 .
docker tag $name:$1 $name:latest
docker run --rm -v "$(pwd)":/myapp $name cp -pf /tmp/Gemfile.lock /myapp
