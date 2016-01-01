FROM ruby:2.2.3
MAINTAINER Your Name <you@example.com>

ENV RACK_ENV production

RUN bundle config --global frozen 1

RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --without test development --system

ADD . /usr/src/app

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-p", "9292", "-E", "production"]
