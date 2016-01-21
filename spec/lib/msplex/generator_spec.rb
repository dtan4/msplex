require "spec_helper"

module Msplex
  describe Generator do
    shared_context :uses_temp_dir do
      around do |example|
        Dir.mktmpdir do |dir|
          @out_dir = dir
          example.run
        end
      end

      attr_reader :out_dir
    end

    include_context :uses_temp_dir

    let(:application) do
      double(:application)
    end

    let(:frontend) do
      double(:frontend)
    end

    let(:services) do
      []
    end

    let(:databases) do
      []
    end

    let(:generator) do
      described_class.new(application, frontend, services, databases, out_dir)
    end

    describe "#generate_compose" do
      let(:application) do
        double(:application,
          name: "sample",
          maintainer: "Tanaka Taro",
          links: [
            { service: "hoge", database: "hoge" },
            { service: "fuga", database: "fuga" },
           ]
        )
      end

      let(:frontend) do
        double(:frontend,
          compose: {
            image: "ruby:2.3.0",
            links: [
              "nginx:hoge",
              "nginx:fuga",
            ]
          }
        )
      end

      let(:services) do
        [
          double(:service,
            name: "hoge",
            compose: {
              build: "services/hoge",
              environment: [
                "VIRTUAL_HOST=hoge",
              ],
              links: [
                "hoge_db:db",
              ],
            },
            compose_service_name: "hoge_service",
          ),
          double(:service,
            name: "fuga",
            compose: {
              build: "services/fuga",
              environment: [
                "VIRTUAL_HOST=fuga",
              ],
              links: [
                "fuga_db:db",
              ],
            },
            compose_service_name: "fuga_service",
          )
        ]
      end

      let(:databases) do
        [
          double(:database,
            name: "hoge",
            compose: {
              image: "postgres:9.4",
            },
            compose_service_name: "hoge_db",
          ),
          double(:database,
            name: "fuga",
            compose: {
              image: "postgres:9.4",
            },
            compose_service_name: "fuga_db",
          )
        ]
      end

      subject { generator.generate_compose }

      it "should generate docker-compose.yml" do
        subject
        expect(File.exists?(File.join(out_dir, "docker-compose.yml"))).to be true
      end

      it "should combine docker-compose.yml of all resources" do
        subject
        expect(open(File.join(out_dir, "docker-compose.yml")).read).to eq <<-COMPOSE
frontend:
  image: ruby:2.3.0
  links:
  - nginx:hoge
  - nginx:fuga
nginx:
  image: jwilder/nginx-proxy:latest
  volumes:
  - "/var/run/docker.sock:/tmp/docker.sock:ro"
hoge_service:
  build: services/hoge
  environment:
  - VIRTUAL_HOST=hoge
  links:
  - hoge_db:db
fuga_service:
  build: services/fuga
  environment:
  - VIRTUAL_HOST=fuga
  links:
  - fuga_db:db
hoge_db:
  image: postgres:9.4
fuga_db:
  image: postgres:9.4
COMPOSE
      end
    end

    describe "#generate_frontend" do
      let(:frontend) do
        double(:frontend,
          app_rb: <<-APPRB,
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
  end

  get "/index" do
    slim :index
  end
end
APPRB
          config_ru: <<-CONFIGRU,
require "rubygems"
require "bundler"
Bundler.require

require "./app.rb"
run App
CONFIGRU
          dockerfile: <<-DOCKERFILE,
FROM ruby:2.3.0
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

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "-p", "9292", "-E", "production"]
DOCKERFILE
          entrypoint_sh: <<-ENTRYPOINT,
#!/bin/bash

bundle exec rake db:create
bundle exec rake db:migrate

exec $@
ENTRYPOINT
          gemfile: <<-GEMFILE,
source "https://rubygems.org"

gem "sinatra"
gem "slim"
gem "sinatra-websocket"
gem "rack_csrf", require: "rack/csrf"
gem "activesupport", require: "active_support/all"
gem "rake"
gem "json"
GEMFILE
          gemfile_lock: <<-GEMFILE_LOCK,
GEM
  remote: https://rubygems.org/
  specs:
    activesupport (4.2.5)
      i18n (~> 0.7)
      json (~> 1.7, >= 1.7.7)
      minitest (~> 5.1)
      thread_safe (~> 0.3, >= 0.3.4)
      tzinfo (~> 1.1)
    i18n (0.7.0)
    json (1.8.3)
    minitest (5.8.3)
    rack (1.6.4)
    rack-protection (1.5.3)
      rack
    rack_csrf (2.5.0)
      rack (>= 1.1.0)
    rake (10.4.2)
    sinatra (1.4.6)
      rack (~> 1.4)
      rack-protection (~> 1.4)
      tilt (>= 1.3, < 3)
    slim (3.0.6)
      temple (~> 0.7.3)
      tilt (>= 1.3.3, < 2.1)
    temple (0.7.6)
    thread_safe (0.3.5)
    tilt (2.0.1)
    tzinfo (1.2.2)
      thread_safe (~> 0.1)

PLATFORMS
  ruby

DEPENDENCIES
  activesupport
  json
  rack_csrf
  rake
  sinatra
  slim

BUNDLED WITH
   1.10.6
GEMFILE_LOCK
          layout_html: <<-HTML,
doctype html
html
  head
    meta charset="utf-8"
    == csrf_meta_tag
    title
      | &lt;script&gt;sample&lt;/script&gt;
  body
    == yield
HTML
          page_htmls: [
            {
              name: "index",
              html: <<-HTML
div#root
  ul
  - @catalog_item_list.each do |obj|
    li obj.name
HTML
            }
          ]
        )
      end

      subject { generator.generate_frontend }

      it "should create frontend directory" do
        subject
        expect(Dir.exists?(File.join(out_dir, "frontend"))).to be true
      end

      it "should generate app.rb" do
        subject
        expect(open(File.join(out_dir, "frontend", "app.rb")).read).to match(/class App < Sinatra::Base/)
      end

      it "should generate config.ru" do
        subject
        expect(open(File.join(out_dir, "frontend", "config.ru")).read).to match(/require "rubygems"/)
      end

      it "should generate Dockerfile" do
        subject
        expect(open(File.join(out_dir, "frontend", "Dockerfile")).read).to match(/FROM ruby:2.3.0/)
      end

      it "should generate entrypoint.sh" do
        subject
        expect(open(File.join(out_dir, "frontend", "entrypoint.sh")).read).to match(/#!\/bin\/bash/)
        expect(File.executable?(File.join(out_dir, "frontend", "entrypoint.sh"))).to eq true
      end

      it "should generate Gemfile" do
        subject
        expect(open(File.join(out_dir, "frontend", "Gemfile")).read).to match(/gem "sinatra"/)
      end

      it "should generate Gemfile.lock" do
        subject
        expect(open(File.join(out_dir, "frontend", "Gemfile.lock")).read).to match(/sinatra \(1\.4\.6\)/)
      end

      it "should generate views/index.slim" do
        subject
        expect(open(File.join(out_dir, "frontend", "views", "index.slim")).read).to match(/div#root/)
      end

      it "should generate views/layout.slim" do
        subject
        expect(open(File.join(out_dir, "frontend", "views", "layout.slim")).read).to match(/doctype html/)
      end
    end

    describe "#generate_services" do
      let(:application) do
        double(:application,
          name: "sample",
          maintainer: "Tanaka Taro",
          links: [
            { service: "hoge", database: "hoge" }
          ]
        )
      end

      let(:services) do
        [
          double(:service,
            name: "hoge",
            app_rb: <<-APPRB,
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
  end

  get "/index" do
    slim :index
  end
end
APPRB
            config_ru: <<-CONFIGRU,
require "rubygems"
require "bundler"
Bundler.require

require "./app.rb"
run App
CONFIGRU
            dockerfile: <<-DOCKERFILE,
FROM ruby:2.3.0
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

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "-p", "9292", "-E", "production"]
DOCKERFILE
          entrypoint_sh: <<-ENTRYPOINT,
#!/bin/bash

bundle exec rake db:create
bundle exec rake db:migrate

exec $@
ENTRYPOINT
            gemfile: <<-GEMFILE,
source "https://rubygems.org"

gem "sinatra"
gem "activesupport", require: "active_support/all"
gem "activerecord"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "rake"
gem "json"
gem "pg", "0.18.3"
GEMFILE
            gemfile_lock: <<-GEMFILE_LOCK,
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
            rakefile: <<-RAKEFILE,
require "sinatra"
require "sinatra/activerecord"
require "sinatra/activerecord/rake"

namespace :db do
  task :load_config do
    require "./app"
  end
end
RAKEFILE
          )
        ]
      end

      let(:databases) do
        [
          double(:database,
            name: "hoge",
            compose: {
              image: "postgres:9.4",
            },
            config: <<-CONFIG,
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  user: postgres
  host: db
  port: 5432

development:
  <<: *default
  database: sample_development

test:
  <<: *default
  database: sample_test

production:
  database: sample_production
CONFIG
            migrations: [
              name: "create_users",
              migration: <<-MIGRATION,
class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end

  def down
    drop_table :users
  end
end
MIGRATION
          ]),
        ]
      end

      subject { generator.generate_services }

      it "should create service directories" do
        subject
        expect(Dir.exists?(File.join(out_dir, "services", "hoge"))).to be true
      end

      it "should generate app.rb" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "app.rb")).read).to match(/class App < Sinatra::Base/)
      end

      it "should generate config.ru" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "config.ru")).read).to match(/require "rubygems"/)
      end

      it "should generate Dockerfile" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "Dockerfile")).read).to match(/FROM ruby:2.3.0/)
      end

      it "should generate entrypoint.sh" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "entrypoint.sh")).read).to match(/#!\/bin\/bash/)
        expect(File.executable?(File.join(out_dir, "services", "hoge", "entrypoint.sh"))).to eq true
      end

      it "should generate Gemfile" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "Gemfile")).read).to match(/gem "sinatra"/)
      end

      it "should generate Gemfile.lock" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "Gemfile.lock")).read).to match(/sinatra \(1\.4\.6\)/)
      end

      it "should generate Rakefile" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "Rakefile")).read).to match(/require "sinatra\/activerecord\/rake"/)
      end

      it "should generate config/database.yml" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "config", "database.yml")).read).to match(/default: &default/)
      end

      it "should generate migration file" do
        subject
        expect(open(File.join(out_dir, "services", "hoge", "db", "migrate", "001_create_users.rb")).read).to match(/class CreateUsers/)
      end
    end
  end
end
