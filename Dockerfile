# syntax=docker/dockerfile:1

FROM ruby:4.0.5-alpine AS builder
RUN apk add --no-cache build-base

ENV BUNDLE_FROZEN=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

WORKDIR /csv-importer
COPY Gemfile* /csv-importer/
RUN --mount=type=cache,target=/usr/local/bundle/cache,sharing=locked \
    bundle install && bundle clean --force

FROM ruby:4.0.5-alpine

# Decrease memory usage
ENV MALLOC_ARENA_MAX=2

# Build arguments — exposed as env vars, consumed by app/main.rb.
# OCI image labels are set by the CI workflow via docker/metadata-action.
ARG BUILDTIME
ENV BUILDTIME=${BUILDTIME}

ARG VERSION
ENV VERSION=${VERSION}

ARG REVISION
ENV REVISION=${REVISION}

LABEL org.opencontainers.image.authors="georg@ledermann.dev"

# Create a non-root user to run the app
RUN addgroup -S app && adduser -S app -G app

WORKDIR /csv-importer

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --chown=app:app . /csv-importer/

USER app

ENTRYPOINT ["bundle", "exec", "app/main.rb"]
