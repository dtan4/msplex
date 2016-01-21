FROM ruby:2.3.0
MAINTAINER Your Name <you@example.com>

ENV RACK_ENV production

WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN bundle install -j4 --without development test --deployment

COPY . /usr/src/app

EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "-p", "80"]
