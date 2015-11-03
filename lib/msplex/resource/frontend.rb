module Msplex
  module Resource
    class Frontend
      attr_reader :name, :elements

      def initialize(name, elements)
        @name = name
        @elements = elements
      end

      def compose
        {
          image: image,
        }
      end

      def dockerfile
        <<-DOCKERFILE
FROM #{image}
MAINTAINER Your Name <you@example.com>

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --without test development --system

ADD . /usr/src/app

RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

EXPOSE 9292
CMD ["bundle", "exec", "rackup", "-p", "9292", "-E", "production"]
        DOCKERFILE
      end

      def gemfile
        <<-GEMFILE
source "https://rubygems.org"

gem "sinatra"
gem "slim"
gem "sinatra-websocket"
gem "rack_csrf", require: "rack/csrf"
gem "activesupport", require: "active_support/all"
gem "rake"
gem "json"
GEMFILE
      end

      def image
        "ruby:2.2.3"
      end
    end
  end
end
