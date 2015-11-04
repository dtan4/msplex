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
            "hogeservice:hogedb",
            "fugaservice:fugadb",
          ]
        )
      end

      let(:frontend) do
        double(:frontend,
          compose: {
            image: "ruby:2.2.3",
            links: [
              "hoge:hoge",
              "fuga:fuga",
            ]
          }
        )
      end

      let(:services) do
        [
          double(:service,
            name: "hogeservice",
            compose: {
              image: "ruby:2.2.3",
              links: [
                "hogedb:db",
              ],
              environment: [
                "RACK_ENV=production",
              ]
            }
          ),
          double(:service,
            name: "fugaservice",
            compose: {
              image: "ruby:2.2.3",
              links: [
                "fugadb:db",
              ],
              environment: [
                "RACK_ENV=production",
              ]
            }
          )
        ]
      end

      let(:databases) do
        [
          double(:database,
            name: "hogedb",
            compose: {
              image: "postgres:9.4",
            }
          ),
          double(:database,
            name: "fugadb",
            compose: {
              image: "postgres:9.4",
            }
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
  image: ruby:2.2.3
  links:
  - hoge:hoge
  - fuga:fuga
hogeservice:
  image: ruby:2.2.3
  links:
  - hogedb:db
  environment:
  - RACK_ENV=production
fugaservice:
  image: ruby:2.2.3
  links:
  - fugadb:db
  environment:
  - RACK_ENV=production
hogedb:
  image: postgres:9.4
fugadb:
  image: postgres:9.4
COMPOSE
      end
    end

    describe "#generate_services" do
      let(:application) do
        double(:application,
          name: "sample",
          maintainer: "Tanaka Taro",
          links: [
            "hogeservice:hogedb",
          ]
        )
      end

      let(:services) do
        [
          double(:service,
            name: "hogeservice",
            dockerfile: <<-DOCKERFILE,
FROM ruby:2.2.3
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
          )
        ]
      end

      let(:databases) do
        [
          double(:database,
            name: "hogedb",
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
  database: sampledb_development

test:
  <<: *default
  database: sampledb_test

production:
  database: sampledb_production
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
        expect(Dir.exists?(File.join(out_dir, "services", "hogeservice"))).to be true
      end

      it "should generate Dockerfile" do
        subject
        expect(open(File.join(out_dir, "services", "hogeservice", "Dockerfile")).read).to match(/FROM ruby:2.2.3/)
      end

      it "should generate Gemfile" do
        subject
        expect(open(File.join(out_dir, "services", "hogeservice", "Gemfile")).read).to match(/gem "sinatra"/)
      end

      it "should generate config/database.yml" do
        subject
        expect(open(File.join(out_dir, "services", "hogeservice", "config", "database.yml")).read).to match(/default: &default/)
      end

      it "should generate migration file" do
        subject
        expect(open(File.join(out_dir, "services", "hogeservice", "db", "001_create_users.rb")).read).to match(/class CreateUsers/)
      end
    end
  end
end
