# syntax=docker/dockerfile:1

FROM ruby:4.0.6-alpine AS builder
RUN apk add --no-cache build-base

ENV BUNDLE_FROZEN=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

WORKDIR /app
COPY Gemfile* /app/
RUN --mount=type=cache,target=/usr/local/bundle/cache,sharing=locked \
    bundle install && bundle clean --force

FROM ruby:4.0.6-alpine

# Decrease memory usage
ENV MALLOC_ARENA_MAX=2

# The Alpine build ships YJIT but leaves it switched off. Reading a row is Ruby
# from end to end - a regex, some arithmetic and a few hashes - which is what
# YJIT is good at: measured in this image, a year of readings went from 2649 ms
# to 2091 ms. RSS grows by about 2 MB.
ENV RUBY_YJIT_ENABLE=1

# Bundler must see the same `without` groups at runtime as at build time,
# otherwise `bundle exec` tries to materialize dev/test gems that were
# never installed into the image.
ENV BUNDLE_FROZEN=1 \
    BUNDLE_WITHOUT=development:test

# Build arguments — exposed as env vars, consumed by app/main.rb.
# OCI image labels are set by the CI workflow via docker/metadata-action.
ARG BUILDTIME
ENV BUILDTIME=${BUILDTIME}

ARG VERSION
ENV VERSION=${VERSION}

LABEL org.opencontainers.image.authors="georg@ledermann.dev"

# Create a non-root user to run the app
RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --chown=app:app . /app/

USER app

ENTRYPOINT ["bundle", "exec", "app/main.rb"]
