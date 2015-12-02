require "spec_helper"

module Msplex
  module Resource
    describe Service do
      let(:name) do
        "sampleservice"
      end

      let(:actions) do
        [
          { type: "create", table: "users" },
          { type: "list", table: "users" },
        ]
      end

      let(:service) do
        described_class.new(name, actions)
      end

      describe ".read_schema" do
        subject { described_class.read_schema(path) }

        context "when the given schema is valid" do
          let(:path) do
            fixture_path("valid_service.yml")
          end

          it { is_expected.to be_a described_class }
          its(:name) { is_expected.to eq "sampleservice" }
          its(:actions) { is_expected.to eql [{ type: "get" }, { type: "list" }] }
        end

        context "when the given schema is invalid" do
          pending
        end
      end

      describe "#app_rb" do
        let(:database) do
          double(:database,
            definitions: [<<-DEFINITION],
class User < ActiveRecord::Base
end
DEFINITION
            params: <<-PARAMS,
user_name = params[:users][:name]
user_description = params[:users][:description]

PARAMS
            list: <<-LIST,
users = User.all
result[:users] = users
LIST
            create: <<-CREATE,
user = User.new(name: user_name)
user.save!
result[:users] ||= []
result[:users] << user
CREATE
          )
        end

        subject { service.app_rb(database) }

        it "should generate app.rb" do
          expect(subject).to eq <<-APPRB
class User < ActiveRecord::Base
end

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

  post "/users" do
    content_type :json
    result = {}

    user_name = params[:users][:name]
    user_description = params[:users][:description]
    user = User.new(name: user_name)
    user.save!
    result[:users] ||= []
    result[:users] << user

    result.to_json
  end

  get "/users" do
    content_type :json
    result = {}

    user_name = params[:users][:name]
    user_description = params[:users][:description]
    users = User.all
    result[:users] = users

    result.to_json
  end
end
APPRB
        end
      end

      describe "#compose" do
        subject { service.compose(database) }

        context "when the service has database" do
          let(:database) do
            double(:database, name: "sampleservice-db", gem: { gem: "pg", version: "0.18.3" })
          end

          it "should generate docker-compose.yml linked with database" do
            expect(subject).to eql({
              build: "services/sampleservice",
              links: [
                "sampleservice-db:db",
              ],
            })
          end
        end

        context "when the service does not have any database" do
          let(:database) do
            nil
          end

          it "should generate docker-compose.yml" do
            expect(subject).to eql({
              build: "services/sampleservice",
              links: [],
            })
          end
        end
      end

      describe "#config_ru" do
        subject { service.config_ru }

        it "should generate config.ru" do
          expect(subject).to eq(<<-CONFIGRU)
require "rubygems"
require "bundler"
Bundler.require

require "./app.rb"
run App
CONFIGRU
        end
      end

      describe "#dockerfile" do
        subject { service.dockerfile }

        it "should generate Dockerfile" do
          expect(subject).to eq(<<-DOCKERFILE)
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
          DOCKERFILE
        end
      end

      describe "#gemfile" do
        subject { service.gemfile(database) }

        context "when the service has database" do
          let(:database) do
            double(:database, name: "sampleservice-db", gem: { gem: "pg", version: "0.18.3" })
          end

          it "should generate Gemfile" do
            expect(subject).to eq <<-GEMFILE
source "https://rubygems.org"

gem "sinatra", require: "sinatra/base"
gem "activesupport", require: "active_support/all"
gem "activerecord"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "rake"
gem "json"
gem "pg", "0.18.3"
GEMFILE
          end
        end

        context "when the service has no database" do
          let(:database) do
            nil
          end

          it "should generate Gemfile without database gem" do
            expect(subject).to eq <<-GEMFILE
source "https://rubygems.org"

gem "sinatra", require: "sinatra/base"
gem "activesupport", require: "active_support/all"
gem "activerecord"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "rake"
gem "json"

GEMFILE
          end
        end
      end

      describe "#gemfile_lock" do
        subject { service.gemfile_lock(database) }

        context "when the service has database" do
          let(:database) do
            double(:database, name: "sampleservice-db", gem: { gem: "pg", version: "0.18.3" })
          end

          it "should generate Gemfile.lock" do
            expect(subject).to eq <<-GEMFILE_LOCK
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
        end

        context "when the service has no database" do
          let(:database) do
            nil
          end

          # TODO: exclude db gem
          it "should generate Gemfile.lock" do
            expect(subject).to eq <<-GEMFILE
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
GEMFILE
          end
        end
      end

      describe "#image" do
        subject { service.image }

        it { is_expected.to eq "ruby:2.2.3" }
      end
    end
  end
end
