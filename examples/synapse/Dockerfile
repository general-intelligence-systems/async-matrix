FROM ruby:3.4-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ../../Gemfile ../../Gemfile.lock ./
RUN bundle install --jobs 4

COPY ../../lib ./lib
COPY . ./examples/echo_bot

EXPOSE 9292

CMD ["bundle", "exec", "falcon", "serve", "--bind", "http://0.0.0.0:9292", "--config", "examples/echo_bot/config.ru"]
