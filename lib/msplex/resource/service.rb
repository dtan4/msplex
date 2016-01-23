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
          type: :patch,
          params: true,
        },
        delete: {
          type: :delete,
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
          environment: [
            "RACK_ENV=production",
            "VIRTUAL_HOST=#{@name}"
          ],
          links: links(database),
        }
      end

      def compose_service_name
        @compose_service_name ||= "#{@name}_service"
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

    def http_get(endpoint, parameters = {})
      uri = URI.parse(parameters.length > 0 ? endpoint + "?" + param_str(parameters) : endpoint)
      JSON.parse(Net::HTTP.get_response(uri).body, symbolize_names: true)
    rescue
      { error: true }
    end

    def http_post(endpoint, parameters)
      uri = URI.parse(endpoint)
      JSON.parse(Net::HTTP.post_form(uri, parameters).body, symbolize_names: true)
    rescue
      { error: true }
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

WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN bundle install -j4 --without development test --deployment

COPY . /usr/src/app

EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "-p", "80"]
DOCKERFILE
      end

      def entrypoint_sh
        <<-ENTRYPOINT
#!/bin/bash

bundle exec rake db:create
bundle exec rake db:migrate

exec $@
ENTRYPOINT
      end

      def gemfile(database)
        <<-GEMFILE.gsub(/^$/, "")
source "https://rubygems.org"

gem "activesupport", require: "active_support/all"
gem "activerecord", "~> 4.2.5"
gem "sinatra", "~> 1.4.6", require: "sinatra/base"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "slim", "~> 3.0.6"
gem "rack_csrf", require: "rack/csrf"
gem "rake"
gem "thin", "~> 1.6.4"
#{db_gem(database)}

group :development do
  gem "sinatra-reloader", require: "sinatra/reloader"
end
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
    backports (3.6.7)
    builder (3.2.2)
    daemons (1.2.3)
    eventmachine (1.0.9.1)
    i18n (0.7.0)
    json (1.8.3)
    minitest (5.8.3)
    multi_json (1.11.2)
    pg (0.18.3)
    rack (1.6.4)
    rack-protection (1.5.3)
      rack
    rack-test (0.6.3)
      rack (>= 1.0)
    rack_csrf (2.5.0)
      rack (>= 1.1.0)
    rake (10.5.0)
    sinatra (1.4.6)
      rack (~> 1.4)
      rack-protection (~> 1.4)
      tilt (>= 1.3, < 3)
    sinatra-activerecord (2.0.9)
      activerecord (>= 3.2)
      sinatra (~> 1.0)
    sinatra-contrib (1.4.6)
      backports (>= 2.0)
      multi_json
      rack-protection
      rack-test
      sinatra (~> 1.4.0)
      tilt (>= 1.3, < 3)
    sinatra-reloader (1.0)
      sinatra-contrib
    slim (3.0.6)
      temple (~> 0.7.3)
      tilt (>= 1.3.3, < 2.1)
    temple (0.7.6)
    thin (1.6.4)
      daemons (~> 1.0, >= 1.0.9)
      eventmachine (~> 1.0, >= 1.0.4)
      rack (~> 1.0)
    thread_safe (0.3.5)
    tilt (2.0.2)
    tzinfo (1.2.2)
      thread_safe (~> 0.1)

PLATFORMS
  ruby

DEPENDENCIES
  activerecord (~> 4.2.5)
  activesupport
  pg (= 0.18.3)
  rack_csrf
  rake
  sinatra (~> 1.4.6)
  sinatra-activerecord
  sinatra-reloader
  slim (~> 3.0.6)
  thin (~> 1.6.4)

BUNDLED WITH
   1.11.2
GEMFILE_LOCK
      end

      def image
        "ruby:2.3.0"
      end

      def rakefile
        <<-RAKEFILE
require "sinatra"
require "sinatra/activerecord"
require "sinatra/activerecord/rake"

namespace :db do
  task :load_config do
    require "./app"
  end
end
RAKEFILE
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

#{defined[:params] ? Utils.indent(database.params(action[:table]), 2) : ""}
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
        database ? ["#{database.compose_service_name}:db"] : []
      end
    end
  end
end
