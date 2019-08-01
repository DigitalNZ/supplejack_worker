FROM ruby:2.5.3

ARG TIMEZONE
ENV TIMEZONE=$TIMEZONE

RUN echo $TIMEZONE > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime
RUN dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    g++ \
    liblzma-dev \
    libxml2-dev \
    libxslt1-dev \
    libxslt-dev \
    mysql-client \
    nodejs \
    nodejs-legacy \
    openssh-client \
    nmap \
   && rm -rf /var/lib/apt/lists/*

RUN groupadd -r worker && useradd -r -m -g worker worker

RUN bundle config build.nokogiri --use-system-libraries

RUN mkdir /var/worker
RUN chown -R worker:worker /var/worker
USER worker

WORKDIR /var/worker

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --binstubs --without development test --path vendor/cache

COPY --chown=worker:worker . .

RUN find / -perm +6000 -type f -exec chmod a-s {} \; || true

EXPOSE 3000
