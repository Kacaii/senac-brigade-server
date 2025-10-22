ARG ERLANG_VERSION=28.0.2.0
ARG GLEAM_VERSION=v1.13.0

# Gleam stage
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Build stage
FROM erlang:${ERLANG_VERSION}-alpine AS build
COPY --from=gleam /bin/gleam /bin/gleam
COPY . /app/
RUN apk add --no-cache build-base
RUN apk add --no-cache postgresql-client
WORKDIR /app
RUN gleam export erlang-shipment

# Final stage
FROM erlang:${ERLANG_VERSION}-alpine
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}
RUN \
  addgroup --system webapp && \
  adduser --system webapp -g webapp
COPY --from=build /app/build/erlang-shipment /app
COPY healthcheck.sh /app/healthcheck.sh
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
