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
    use Rack::Session::Cookie, expire_after: 3600, secret: "salt"
    use Rack::Csrf, raise: true
    Slim::Engine.options[:pretty] = true
  end

  configure :development do
    register Sinatra::Reloader
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

#{Utils.indent(endpoints, 2)}
end
APPRB
      end

      def compose(services)
        {
          build: "frontend",
          links: links(services),
          ports: [
            "80:9292"
          ]
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

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bundle", "exec", "rackup", "-p", "9292", "-E", "production"]
        DOCKERFILE
      end

      def entrypoint_sh
        <<-ENTRYPOINT
#!/bin/bash

exec $@
ENTRYPOINT
      end

      def gemfile
        <<-GEMFILE
source "https://rubygems.org"

gem "activesupport", require: "active_support/all"
gem "sinatra", "~> 1.4.6", require: "sinatra/base"
gem "slim", "~> 3.0.6"
gem "rack_csrf", require: "rack/csrf"
gem "rake"
gem "thin", "~> 1.6.4"

group :development do
  gem "sinatra-reloader", require: "sinatra/reloader"
end
GEMFILE
      end

      def gemfile_lock
        <<-GEMFILE_LOCK
GEM
  remote: https://rubygems.org/
  specs:
    activesupport (4.2.5)
      i18n (~> 0.7)
      json (~> 1.7, >= 1.7.7)
      minitest (~> 5.1)
      thread_safe (~> 0.3, >= 0.3.4)
      tzinfo (~> 1.1)
    backports (3.6.7)
    daemons (1.2.3)
    eventmachine (1.0.9.1)
    i18n (0.7.0)
    json (1.8.3)
    minitest (5.8.3)
    multi_json (1.11.2)
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
  activesupport
  rack_csrf
  rake
  sinatra (~> 1.4.6)
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
    script src="https://code.jquery.com/jquery-2.2.0.min.js"
    script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"
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
        services.map { |service| "nginx:#{service.name}" }
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
