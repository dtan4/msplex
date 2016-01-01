FROM ruby:2.2.3
MAINTAINER Your Name <you@example.com>

ENV RACK_ENV production

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --without test development --system

ADD . /usr/src/app

EXPOSE 80
CMD ["bundle", "exec", "rackup", "-p", "80", "-E", "production"]
