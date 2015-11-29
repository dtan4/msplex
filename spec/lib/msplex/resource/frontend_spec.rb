require "spec_helper"

module Msplex
  module Resource
    describe Frontend do
      let(:pages) do
        [
          {
            name: "index",
            # FIXME
            elements: <<-ELEMENTS,
div#root
  ul
  - @catalog_item_list.each do |obj|
    li obj.name
ELEMENTS
            variables: {
              users: { service: "user", table: "users", action: "list" },
            }
          },
          {
            name: "search",
            # FIXME
            elements: <<-ELEMENTS,
div#root
  input#searchKeyword type: text
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

      describe "#app_rb" do
        subject { frontend.app_rb }

        it "should generate app.rb" do
          expect(subject).to eq <<-APPRB
class App < Sinatra::Base
  configure do
    register Sinatra::ActiveRecordExtension
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

  get "/" do
    slim :index, locals: { users: http_get(endpoint_of("user", "users/list")) }
  end

  get "/search" do
    slim :search, locals: {  }
  end
end
APPRB
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
              build: "frontend",
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
              build: "frontend",
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

      describe "#layout_html" do
        let(:application) do
          double(:application, name: "<script>sample</script>")
        end

        subject { frontend.layout_html(application) }

        it "should generate Slim template of layout" do
          expect(subject).to eq <<-HTML
doctype html
html
  head
    meta charset="utf-8"
    == csrf_meta_tag
    title
      | &lt;script&gt;sample&lt;/script&gt;
    link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet"
    script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"
  body
    nav.navbar.navbar-default
      .container-fluid
        .navbar-header
          a.navbar-brand href="/" &lt;script&gt;sample&lt;/script&gt;
        .collapse.navbar-collapse#bs-navbar-collapse-1
          ul.nav.navbar-nav
            li
              a href="/" Index
            li
              a href="/search" Search
    .container
      == yield
HTML
        end
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
            },
            {
              name: "search",
              html: <<-HTML
div#root
  input#searchKeyword type: text
HTML
            }
          ])
        end
      end
    end
  end
end
