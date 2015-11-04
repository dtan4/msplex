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

    let(:generator) do
      described_class.new(application, frontend, services, databases, out_dir)
    end

    describe "#generate_compose" do
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
  end
end
