FROM ruby:4.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4

COPY lib ./lib
COPY examples/synapse ./examples/synapse

EXPOSE 9292

CMD ["bundle", "exec", "falcon", "serve", "--bind", "http://0.0.0.0:9292", "--config", "examples/synapse/config.ru"]
