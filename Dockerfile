FROM ruby:2.6.5-alpine AS builder

ARG BUILD_PACKAGES="build-base curl-dev git"
ARG DEV_PACKAGES="yaml-dev zlib-dev libxml2-dev libxslt-dev"
ARG RUBY_PACKAGES="tzdata"

WORKDIR /app

# install packages
RUN apk add --no-cache $BUILD_PACKAGES $DEV_PACKAGES $RUBY_PACKAGES

COPY Gemfile Gemfile.lock ./
# COPY vendor/cache ./vendor/cache

# install rubygem
RUN gem install bundler -v $(tail -n1 Gemfile.lock) \
    && bundle config --global frozen 1 \
    && bundle install --path=vendor/cache --without development:test:assets -j4 --retry 3 \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    && rm -rf $GEM_HOME/cache/*.gem \
    && find $GEM_HOME/gems/ -name "*.c" -delete \
    && find $GEM_HOME/gems/ -name "*.o" -delete

# Change TimeZone
ENV TZ=Pacific/Auckland

COPY . .

ARG RAILS_ENV="production"
ARG SECRET_KEY_BASE

ENV RAILS_ENV=$RAILS_ENV

############### Build step done ###############

FROM ruby:2.6.5-alpine

ARG PACKAGES="build-base tzdata bash libxslt libxml2-dev libxslt-dev"

# Change TimeZone
ENV TZ=Pacific/Auckland

WORKDIR /app

# install packages
RUN apk add --no-cache $PACKAGES

COPY --from=builder $GEM_HOME $GEM_HOME
COPY --from=builder /app /app

ARG RAILS_ENV="production"
ENV RAILS_ENV=$RAILS_ENV
EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
