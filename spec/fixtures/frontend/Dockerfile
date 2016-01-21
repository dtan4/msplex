FROM ruby:2.3.0
MAINTAINER Your Name <you@example.com>

ENV RACK_ENV production

RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN bundle install -j4 --without development test --deployment

COPY . /usr/src/app

EXPOSE 9292

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "-p", "9292"]
