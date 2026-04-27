FROM ruby:3.4

RUN apt-get update && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4

COPY . .

EXPOSE 9292

CMD ["bundle", "exec", "falcon", "serve", "--bind", "http://0.0.0.0:9292", "--config", "config.ru"]
