require "spec_helper"

module Msplex
  module Resource
    describe Database do
      let(:type) do
        :rdb
      end

      let(:name) do
        "sampledb"
      end

      let(:tables) do
        {
          users: [
            { key: "id", type: :int },
            { key: "name", type: :string },
            { key: "description", type: :string },
          ],
          items: [
            { key: "id", type: :int },
            { key: "name", type: :string },
          ]
        }
      end

      let(:database) do
        described_class.new(type, name, tables)
      end

      describe ".read_schema" do
        subject { described_class.read_schema(path) }

        context "when the given schema is valid" do
          let(:path) do
            fixture_path("valid_database.yml")
          end

          it { is_expected.to be_a described_class }
          its(:name) { is_expected.to eq "sampledb" }
          its(:tables) { is_expected.to eql({ users: [{ key: "name", type: "string" }, { key: "description", type: "string" }] }) }
        end

        context "when the given schema is invalid" do
          pending
        end
      end

      describe "#initialize" do
        context "if type is :rdb" do
          let(:type) do
            :rdb
          end

          it "should return new Database instance" do
            expect(database).to be_a Msplex::Resource::Database
          end
        end

        context "if type is :kvs" do
          let(:type) do
            :kvs
          end

          it "should return new Database instance" do
            expect(database).to be_a Msplex::Resource::Database
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

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:compose)
          subject
        end
      end

      describe "#config" do
        subject { database.config }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:config)
          subject
        end
      end

      describe "#definitions" do
        subject { database.definitions }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:definitions)
          subject
        end
      end

      describe "#gem" do
        subject { database.gem }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:gem)
          subject
        end
      end

      describe "#image" do
        subject { database.image }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:image)
          subject
        end
      end

      describe "#migrations" do
        subject { database.migrations }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:migrations)
          subject
        end
      end

      describe "#create" do
        subject { database.create }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:create)
          subject
        end
      end

      describe "#read" do
        subject { database.read }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDB).to receive(:read)
          subject
        end
      end
    end
  end
end
