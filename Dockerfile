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
WORKDIR $APP_HOME
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install
ADD . $APP_HOME

CMD bundle exec ruby app.rb
