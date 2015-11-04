require "spec_helper"

module Msplex
  module Resource
    describe Frontend do
      let(:pages) do
        [
          {
            name: "index",
            # FIXME
            elements: <<-ELEMENTS
div#root
  ul
  - @catalog_item_list.each do |obj|
    li obj.name
ELEMENTS
          }
        ]
      end

      let(:frontend) do
        described_class.new(pages)
      end

      describe ".read_schema" do
        subject { described_class.read_schema(path) }

        context "when the given schema is valid" do
          let(:path) do
            fixture_path("valid_frontend.yml")
          end

          it { is_expected.to be_a described_class }
          its(:pages) { is_expected.to be_a Array }
        end

        context "when the given schema is invalid" do
          pending
        end
      end

      describe "#compose" do
        subject { frontend.compose(services) }

        context "when the frontend has services" do
          let(:services) do
            [
              double(:hoge_service, name: "hoge"),
              double(:fuga_service, name: "fuga"),
            ]
          end

          it "should generate docker-compose.yml linked with services" do
            expect(subject).to eql({
              image: "ruby:2.2.3",
              links: [
                "hoge:hoge",
                "fuga:fuga",
              ]
            })
          end
        end

        context "when the frontend has no service" do
          let(:services) do
            []
          end

          it "should generate docker-compose.yml linked with services" do
            expect(subject).to eql({
              image: "ruby:2.2.3",
              links: [],
            })
          end
        end
      end

      describe "#config_ru" do
        subject { frontend.config_ru }

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
        subject { frontend.dockerfile }

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
        subject { frontend.gemfile }

        it "should generate Gemfile" do
          expect(subject).to eq <<-GEMFILE
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
      end

      describe "#image" do
        subject { frontend.image }

        it { is_expected.to eq "ruby:2.2.3" }
      end

      describe "#page_htmls" do
        subject { frontend.page_htmls }

        it "should generate Slim templates" do
          expect(subject).to eql([
            {
              name: "index",
              html: <<-HTML
div#root
  ul
  - @catalog_item_list.each do |obj|
    li obj.name
HTML
            }
          ])
        end
      end
    end
  end
end
