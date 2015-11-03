require "spec_helper"

module Msplex
  module Resource
    describe Service do
      let(:name) do
        "sampleservice"
      end

      let(:actions) do
        []
      end

      let(:database) do
        double(:database, name: "sampleservice-db", gem: { gem: "pg", version: "0.18.3" })
      end

      let(:service) do
        described_class.new(name, actions, database)
      end

      describe "#compose" do
        subject { service.compose }

        context "when the service has database" do
          it "should generate docker-compose.yml linked with database" do
            expect(subject).to eql({
              image: "ruby:2.2.3",
              links: [
                "sampleservice-db:db",
              ],
              environment: [
                "DB_HOST=db",
              ]
            })
          end
        end

        context "when the service does not have any database" do
          let(:database) do
            nil
          end

          it "should generate docker-compose.yml" do
            expect(subject).to eql({
              image: "ruby:2.2.3"
            })
          end
        end
      end

      describe "#dockerfile" do
        subject { service.dockerfile }

        it "should generate Dockerfile" do
          expect(subject).to eq(<<-DOCKERFILE)
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
        end
      end

      describe "#gemfile" do
        subject { service.gemfile }

        it "should generate Gemfile" do
          expect(subject).to eq <<-GEMFILE
source "https://rubygems.org"

gem "sinatra"
gem "slim"
gem "sinatra-websocket"
gem "rack_csrf", require: "rack/csrf"
gem "activesupport", require: "active_support/all"
gem "activerecord"
gem "sinatra-activerecord", require: "sinatra/activerecord"
gem "pg", "0.18.3"
gem "rake"
gem "json"
GEMFILE
        end
      end

      describe "#image" do
        subject { service.image }

        it { is_expected.to eq "ruby:2.2.3" }
      end
    end
  end
end
