#!bash
docker build -t webapi:$1 .
docker tag webapi:$1 webapi:latest
docker run --rm -it -v `pwd`:/myapp webapi bundle install
