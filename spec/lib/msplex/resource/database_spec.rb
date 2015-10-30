require "spec_helper"

module Msplex
  module Resource
    describe Database do
      let(:name) do
        "sampledb"
      end

      let(:type) do
        :rds
      end

      let(:fields) do
        [
          { key: "id", type: :int },
          { key: "name", type: :string },
          { key: "description", type: :string },
        ]
      end

      let(:database) do
        described_class.new(name, type, fields)
      end

      describe "#initialize" do
        context "if type is :rds" do
          let(:type) do
            :rds
          end

          it "should return new Database instance" do
            expect(database).to be_a described_class
          end
        end

        context "if type is :kvs" do
          let(:type) do
            :kvs
          end

          it "should return new Database instance" do
            expect(database).to be_a described_class
          end
        end

        context "if type is unknown" do
          let(:type) do
            :unknown
          end

          it "should rails InvalidTypeError" do
            expect do
              database
            end.to raise_error InvalidDatabaseTypeError, "unknown is invalid database type"
          end
        end
      end

      describe "#compose" do
        subject { database.compose }

        context "if type is :rds" do
          let(:type) do
            :rds
          end

          it "should generate docker-compose.yml" do
            expect(subject).to eql({
              image: "postgres:9.4",
            })
          end
        end

        context "if type is :kvs" do
          let(:type) do
            :kvs
          end

          it "should generate docker-compose.yml" do
            expect(subject).to eql({
              image: "redis:3.0",
            })
          end
        end
      end

      describe "#gem" do
        subject { database.gem }

        context "if type is :rds" do
          let(:type) do
            :rds
          end

          it "should return adapter gem and its version" do
            expect(subject).to eql({
              gem: "pg",
              version: "0.18.3",
            })
          end
        end

        context "if type is :kvs" do
          let(:type) do
            :kvs
          end

          it "should return adapter gem adn its version" do
            expect(subject).to eql({
              gem: "redis",
              version: "3.2.1",
            })
          end
        end
      end

      describe "#image" do
        subject { database.image }

        context "if type is :rds" do
          let(:type) do
            :rds
          end

          it { is_expected.to eq "postgres:9.4" }
        end

        context "if type is :kvs" do
          let(:type) do
            :kvs
          end

          it { is_expected.to eq "redis:3.0" }
        end
      end

      describe "#rds?" do
        subject { database.rds? }

        context "if type is :rds" do
          let(:type) do
            :rds
          end

          it { is_expected.to eq true }
        end

        context "if type is :kvs" do
          let(:type) do
            :kvs
          end

          it { is_expected.to eq false }
        end
      end
    end
  end
end
