FROM ruby:4.0.5-alpine AS builder
RUN apk add --no-cache build-base

WORKDIR /csv-importer
COPY Gemfile* /csv-importer/
RUN bundle config --local frozen 1 && \
    bundle config --local without 'development test' && \
    bundle install -j4 --retry 3 && \
    bundle clean --force

FROM ruby:4.0.5-alpine
LABEL maintainer="georg@ledermann.dev"

# Decrease memory usage
ENV MALLOC_ARENA_MAX=2

# Move build arguments to environment variables
ARG BUILDTIME
ENV BUILDTIME=${BUILDTIME}

ARG VERSION
ENV VERSION=${VERSION}

ARG REVISION
ENV REVISION=${REVISION}

# Create a non-root user to run the app
RUN addgroup -S app && adduser -S app -G app

WORKDIR /csv-importer

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --chown=app:app . /csv-importer/

USER app

ENTRYPOINT ["bundle", "exec", "app/main.rb"]
