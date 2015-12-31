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
          expect(subject).to eq open(fixture_path("frontend/app.rb")).read
        end
      end

      describe "#compose" do
        subject { frontend.compose(services) }

        context "when the frontend has services" do
          let(:services) do
            [
              double(:hoge, name: "hoge", compose_service_name: "hoge_service"),
              double(:fuga, name: "fuga", compose_service_name: "fuga_service"),
            ]
          end

          it "should generate docker-compose.yml linked with services" do
            expect(subject).to eql({
              build: "frontend",
              links: [
                "hoge_service:hoge",
                "fuga_service:fuga",
              ],
              ports: [
                "80:9292"
              ],
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
              ports: [
                "80:9292"
              ],
            })
          end
        end
      end

      describe "#config_ru" do
        subject { frontend.config_ru }

        it "should generate config.ru" do
          expect(subject).to eq open(fixture_path("frontend/config.ru")).read
        end
      end

      describe "#dockerfile" do
        subject { frontend.dockerfile }

        it "should generate Dockerfile" do
          expect(subject).to eq open(fixture_path("frontend/Dockerfile")).read
        end
      end

      describe "#gemfile" do
        subject { frontend.gemfile }

        it "should generate Gemfile" do
          expect(subject).to eq <<-GEMFILE
source "https://rubygems.org"

gem "sinatra", require: "sinatra/base"
gem "slim"
gem "rack_csrf", require: "rack/csrf"
gem "activesupport", require: "active_support/all"
gem "rake"
gem "json"

group :development do
  gem "sinatra-reloader", require: "sinatra/reloader"
end
GEMFILE
        end
      end

      describe "#gemfile_lock" do
        subject { frontend.gemfile_lock }

        it "should generate Gemfile.lock" do
          expect(subject).to eq <<-GEMFILE_LOCK
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
    rake (10.4.2)
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
  sinatra-reloader
  slim

BUNDLED WITH
   1.10.6
GEMFILE_LOCK
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
