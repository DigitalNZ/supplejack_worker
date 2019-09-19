FROM ruby:2.3.1
RUN apt-get update -qq && apt-get install -y build-essential nodejs npm nodejs-legacy mysql-client vim openssh-client
RUN apt-get install -y g++ cron

# For nokogiri
RUN apt-get install -y libxml2-dev libxslt1-dev libxslt-dev liblzma-dev curl

# Utilities
RUN apt-get install -y nmap htop

# Use libxml2, libxslt a packages from alpine for building nokogiri
RUN bundle config build.nokogiri --use-system-libraries

RUN mkdir /var/worker
RUN mkdir -p /var/worker/tmp/pids

# Cache bundle install
WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
ENV BUNDLE_PATH /bundle
RUN bundle install

WORKDIR /var/worker
ADD . /var/worker

