require "spec_helper"

module Msplex
  module Resource
    describe Service do
      let(:name) do
        "sample"
      end

      let(:actions) do
        [
          { type: "create", table: "users" },
          { type: "list", table: "users" },
        ]
      end

      let(:service) do
        described_class.new(name, actions)
      end

      describe ".read_schema" do
        subject { described_class.read_schema(path) }

        context "when the given schema is valid" do
          let(:path) do
            fixture_path("valid_service.yml")
          end

          it { is_expected.to be_a described_class }
          its(:name) { is_expected.to eq "sample" }
          its(:actions) { is_expected.to eql [{ type: "get" }, { type: "list" }] }
        end

        context "when the given schema is invalid" do
          pending
        end
      end

      describe "#app_rb" do
        let(:database) do
          double(:database,
            definitions: [<<-DEFINITION],
class User < ActiveRecord::Base
end
DEFINITION
            params: <<-PARAMS,
json_params = JSON.parse(request.body.read)
user_name = json_params[:users][:name]
user_description = json_params[:users][:description]

PARAMS
            list: <<-LIST,
users = User.all
result[:users] = users
LIST
            create: <<-CREATE,
user = User.new(name: user_name)
user.save!
result[:users] ||= []
result[:users] << user
CREATE
          )
        end

        subject { service.app_rb(database) }

        it "should generate app.rb" do
          expect(subject).to eq fixture_of("service", "app.rb")
        end
      end

      describe "#compose" do
        subject { service.compose(database) }

        context "when the service has database" do
          let(:database) do
            double(:database, name: "sample", compose_service_name: "sample_db", gem: { gem: "pg", version: "0.18.3" })
          end

          it "should generate docker-compose.yml linked with database" do
            expect(subject).to eql({
              build: "services/sample",
              links: [
                "sample_db:db",
              ],
            })
          end
        end

        context "when the service does not have any database" do
          let(:database) do
            nil
          end

          it "should generate docker-compose.yml" do
            expect(subject).to eql({
              build: "services/sample",
              links: [],
            })
          end
        end
      end

      describe "#compose_service_name" do
        subject { service.compose_service_name}

        it { is_expected.to eq "sample_service" }
      end

      describe "#config_ru" do
        subject { service.config_ru }

        it "should generate config.ru" do
          expect(subject).to eq fixture_of("service", "config.ru")
        end
      end

      describe "#dockerfile" do
        subject { service.dockerfile }

        it "should generate Dockerfile" do
          expect(subject).to eq fixture_of("service", "Dockerfile")
        end
      end

      describe "#entrypoint_sh" do
        subject { service.entrypoint_sh }

        it "should generate enrtypoint.sh" do
          expect(subject).to eq fixture_of("service", "entrypoint.sh")
        end
      end

      describe "#gemfile" do
        subject { service.gemfile(database) }

        context "when the service has database" do
          let(:database) do
            double(:database, name: "sampleservice-db", gem: { gem: "pg", version: "0.18.3" })
          end

          it "should generate Gemfile" do
            expect(subject).to eq fixture_of("service", "Gemfile.db")
          end
        end

        context "when the service has no database" do
          let(:database) do
            nil
          end

          it "should generate Gemfile without database gem" do
            expect(subject).to eq fixture_of("service", "Gemfile.no_db")
          end
        end
      end

      describe "#gemfile_lock" do
        subject { service.gemfile_lock(database) }

        context "when the service has database" do
          let(:database) do
            double(:database, name: "sampleservice-db", gem: { gem: "pg", version: "0.18.3" })
          end

          it "should generate Gemfile.lock" do
            expect(subject).to eq fixture_of("service", "Gemfile.lock.db")
          end
        end

        context "when the service has no database" do
          let(:database) do
            nil
          end

          # TODO: exclude db gem
          it "should generate Gemfile.lock" do
            expect(subject).to eq fixture_of("service", "Gemfile.lock.no_db")
          end
        end
      end

      describe "#image" do
        subject { service.image }

        it { is_expected.to eq "ruby:2.3.0" }
      end

      describe "#rakefile" do
        subject { service.rakefile }

        it "should generate Rakefile" do
          expect(subject).to eq fixture_of("service", "Rakefile")
        end
      end
    end
  end
end
