require "spec_helper"

module Msplex
  module Resource
    describe Database do
      let(:type) do
        :rds
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

      describe "#initialize" do
        context "if type is :rds" do
          let(:type) do
            :rds
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
          expect_any_instance_of(Msplex::Resource::RDS).to receive(:compose)
          subject
        end
      end

      describe "#config" do
        subject { database.config }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDS).to receive(:config)
          subject
        end
      end

      describe "#find" do
        subject { database.find }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDS).to receive(:find)
          subject
        end
      end

      describe "#gem" do
        subject { database.gem }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDS).to receive(:gem)
          subject
        end
      end

      describe "#image" do
        subject { database.image }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDS).to receive(:image)
          subject
        end
      end

      describe "#migration" do
        subject { database.migration }

        it "should delegate to child class" do
          expect_any_instance_of(Msplex::Resource::RDS).to receive(:migration)
          subject
        end
      end
    end
  end
end
