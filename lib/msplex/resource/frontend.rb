module Msplex
  module Resource
    class Frontend
      attr_reader :pages

      def self.read_schema(path)
        schema = Utils.symbolize_keys(YAML.load_file(path))
        self.new(schema[:pages])
      end

      def initialize(pages)
        @pages = pages
      end

      def app_rb
        <<-APPRB
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

#{Utils.indent(endpoints, 2)}
end
APPRB
      end

      def compose(services)
        {
          build: "frontend",
          links: links(services),
        }
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

      def gemfile
        <<-GEMFILE
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

      def image
        "ruby:2.2.3"
      end

      def layout_html(application)
        <<-HTML
doctype html
html
  head
    meta charset="utf-8"
    == csrf_meta_tag
    title
      | #{ERB::Util.html_escape(application.name)}
    link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet"
    script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"
  body
    nav.navbar.navbar-default
      .container-fluid
        .navbar-header
          a.navbar-brand href="/" #{ERB::Util.html_escape(application.name)}
        .collapse.navbar-collapse#bs-navbar-collapse-1
          ul.nav.navbar-nav
#{Utils.indent(navbar_items, 12)}
    .container
      == yield
HTML
      end

      def page_htmls
        pages.map { |page| { name: page[:name], html: convert_to_slim(page[:elements]) } }
      end

      private

      def convert_to_slim(elements)
        # TODO
        elements
      end

      def endpoint_of(page)
        page[:name] == "index" ? "/" : "/#{page[:name]}"
      end

      def endpoints
        @pages.map do |page|
          <<-ENDPOINT
get "#{endpoint_of(page)}" do
  slim :#{page[:name]}, locals: { #{variable_assignments(page)} }
end
ENDPOINT
        end.join("\n")
      end

      def links(services)
        services.map { |service| "#{service.name}:#{service.name}" }
      end

      def navbar_items
        @pages.map do |page|
          <<-ITEM.strip
li
  a href="#{endpoint_of(page)}" #{page[:name].capitalize}
ITEM
        end.join("\n")
      end

      def variable_assignments(page)
        return "" unless page[:variables]

        page[:variables].map do |name, value|
          <<-ASSIGNMENT.strip
#{name}: http_get(endpoint_of("#{value[:service]}", "#{value[:table]}/#{value[:action]}"))
ASSIGNMENT
        end.join(",")
      end
    end
  end
end
