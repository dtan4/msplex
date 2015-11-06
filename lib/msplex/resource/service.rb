module Msplex
  module Resource
    class Service
      DEFINED_ACTION = {
        list: { type: :get },
        create: { type: :post },
        get: { type: :get },
        update: { type: :post }, # PATCH
        delete: { type: :post }, # DELETE
      }

      attr_reader :name, :actions

      def self.read_schema(path)
        schema = Utils.symbolize_keys(YAML.load_file(path))
        self.new(schema[:name], schema[:actions])
      end

      def initialize(name, actions)
        @name = name
        @actions = actions
      end

      def compose(database)
        {
          image: image,
          links: links(database),
        }
      end

      def app_rb(database)
        <<-APPRB
#{database.definitions.join("\n")}
class App < Sinatra::Base
  configure do
    register Sinatra::ActiveRecordExtension
    set :sockets, []
    use Rack::Session::Cookie, expire_after: 3600, secret: "salt"
    use Rack::Csrf, raise: true
    Slim::Engine.default_options[:pretty] = true
  end

  helpers do
    def csrf_meta_tag
      Rack::Csrf.csrf_metatag(env)
    end

    def param_str(parameters)
      parameters.map { |key, value| key.to_s + "=" + CGI.escape(value.to_s) }.join("&")
    end

    def http_get(endpoint, parameters)
      uri = URI.parse(endpoint + "?" + param_str(parameters))
      JSON.parse(Net::HTTP.get_response(uri).body, symbolize_names: true)
    rescue
      {}
    end

    def http_post(endpoint, parameters)
      uri = URI.parse(endpoint)
      JSON.parse(Net::HTTP.post_form(uri, parameters).body, symbolize_names: true)
    rescue
      {}
    end

    def endpoint_of(service, action)
      "http://" << service << "/" << action
    end
  end

#{Utils.indent(endpoint(database), 2)}
end
APPRB
      end

      def config_ru
        <<-CONFIGRU
require "rubygems"
require "bundler"
Bundler.require

require "./app.rb"
run App
CONFIGRU
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

      def gemfile(database)
        <<-GEMFILE
source "https://rubygems.org"

gem "sinatra"
gem "activesupport", require: "active_support/all"
gem "activerecord"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "rake"
gem "json"
#{db_gem(database)}
GEMFILE
      end

      def image
        "ruby:2.2.3"
      end

      private

      def db_gem(database)
        database ? "gem #{database.gem[:gem].inspect}, #{database.gem[:version].inspect}" : ""
      end

      def endpoint(database)
        actions.map do |action|
          if DEFINED_ACTION.keys.include?(action[:type].to_sym)
            defined = DEFINED_ACTION[action[:type].to_sym]
            <<-ENDPOINT
#{defined[:type]} "/#{action[:table]}" do
  content_type :json
  result = {}

#{Utils.indent(database.params, 2)}
#{Utils.indent(database.send(action[:type]), 2)}

  result.to_json
end
ENDPOINT
          else
            # TODO
            ""
          end
        end.join("\n")
      end

      def links(database)
        database ? ["#{database.name}:db"] : []
      end
    end
  end
end
