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

#{Utils.indent(endpoints, 2)}
end
APPRB
      end

      def compose(services)
        {
          image: image,
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
  body
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

      def endpoints
        @pages.map do |page|
          <<-ENDPOINT
get "/#{page[:name]}" do
  slim :#{page[:name]}
end
ENDPOINT
        end.join("\n")
      end

      def links(services)
        services.map { |service| "#{service.name}:#{service.name}" }
      end
    end
  end
end
