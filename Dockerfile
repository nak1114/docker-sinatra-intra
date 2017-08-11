FROM ruby:2.4.1
ENV LANG C.UTF-8
# for postgreSQL
#RUN apt-get update -qq && apt-get install -y build-essential libpq-dev  nodejs
# for mariaDB
RUN apt-get update -qq \
 && apt-get install -y debian-archive-keyring \
 && apt-get update -qq \
 && apt-get install -y build-essential mysql-client nodejs zip \
 && gem install bundler

ENV APP_HOME /myapp
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

WORKDIR $APP_HOME
ADD . $APP_HOME
RUN cp -f /tmp/Gemfile.lock $APP_HOME

CMD bundle exec ruby app.rb
