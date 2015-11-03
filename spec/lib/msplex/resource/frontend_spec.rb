require "spec_helper"

module Msplex
  module Resource
    describe Frontend do
      let(:name) do
        "sample"
      end

      let(:elements) do
        []
      end

      let(:frontend) do
        described_class.new(name, elements)
      end

      describe "#compose" do
        subject { frontend.compose }

        it "should generate docker-compose.yml" do
          expect(subject).to eql({
            image: "ruby:2.2.3"
          })
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
    end
  end
end
