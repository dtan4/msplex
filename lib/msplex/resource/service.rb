module Msplex
  module Resource
    class Service
      attr_reader :name, :actions, :database

      def initialize(name, actions, database)
        @name = name
        @actions = actions
        @database = database
      end

      def compose
        {
          image: image,
        }.merge(db_links)
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

      def image
        "ruby:2.2.3"
      end

      private

      def db_links
        return {} if @database.nil?

        {
          links: [
            "#{@database.name}:db",
          ],
          environment: [
            "DB_HOST=db"
          ]
        }
      end
    end
  end
end
