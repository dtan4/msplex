module Msplex
  module Resource
    class Service
      DEFINED_ACTION = {
        list: {
          type: :get,
          params: false,
        },
        create: {
          type: :post,
          params: true,
        },
        get: {
          type: :get,
          params: true,
        },
        update: {
          type: :post, # PATCH
          params: true,
        },
        delete: {
          type: :post, # DELETE
          params: true,
        },
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
          build: "services/#{@name}",
          links: links(database),
        }
      end

      def app_rb(database)
        <<-APPRB
#{database.definitions.join("\n")}
class App < Sinatra::Base
  configure do
    register Sinatra::ActiveRecordExtension
    use Rack::Session::Cookie, expire_after: 3600, secret: "salt"
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

ENV RACK_ENV production

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

gem "sinatra", require: "sinatra/base"
gem "activesupport", require: "active_support/all"
gem "activerecord"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "rake"
gem "json"
#{db_gem(database)}
GEMFILE
      end

      def gemfile_lock(database)
        <<-GEMFILE_LOCK
GEM
  remote: https://rubygems.org/
  specs:
    activemodel (4.2.5)
      activesupport (= 4.2.5)
      builder (~> 3.1)
    activerecord (4.2.5)
      activemodel (= 4.2.5)
      activesupport (= 4.2.5)
      arel (~> 6.0)
    activesupport (4.2.5)
      i18n (~> 0.7)
      json (~> 1.7, >= 1.7.7)
      minitest (~> 5.1)
      thread_safe (~> 0.3, >= 0.3.4)
      tzinfo (~> 1.1)
    arel (6.0.3)
    builder (3.2.2)
    i18n (0.7.0)
    json (1.8.3)
    minitest (5.8.3)
    pg (0.18.3)
    rack (1.6.4)
    rack-protection (1.5.3)
      rack
    rake (10.4.2)
    sinatra (1.4.6)
      rack (~> 1.4)
      rack-protection (~> 1.4)
      tilt (>= 1.3, < 3)
    sinatra-activerecord (2.0.9)
      activerecord (>= 3.2)
      sinatra (~> 1.0)
    thread_safe (0.3.5)
    tilt (2.0.1)
    tzinfo (1.2.2)
      thread_safe (~> 0.1)

PLATFORMS
  ruby

DEPENDENCIES
  activerecord
  activesupport
  json
  pg (= 0.18.3)
  rake
  sinatra
  sinatra-activerecord

BUNDLED WITH
   1.10.6
GEMFILE_LOCK
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
            db_action = defined[:params] ?
              database.send(action[:type], action[:table], {}) : database.send(action[:type], action[:table])
            <<-ENDPOINT
#{defined[:type]} "/#{action[:table]}" do
  content_type :json
  result = {}

#{Utils.indent(database.params(action[:table]), 2)}
#{Utils.indent(db_action, 2)}

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
