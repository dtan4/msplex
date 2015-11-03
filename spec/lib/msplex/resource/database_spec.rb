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
        described_class.new(name, type, tables)
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

      describe "#config" do
        subject { database.config }

        context "if type if :rds" do
          let(:type) do
            :rds
          end

          it "should generate database.yml" do
            expect(subject).to eq <<-CONFIG
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  user: postgres
  host: db
  port: 5432

development:
  <<: *default
  database: sampledb_development

test:
  <<: *default
  database: sampledb_test

production:
  database: sampledb_production
CONFIG
          end
        end

        context "if type if :kvs" do
          let(:type) do
            :kvs
          end

          it { is_expected.to eq "" }
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

      describe "#migration" do
        subject { database.migration }

        context "if type is :rds" do
          let(:type) do
            :rds
          end

          it "should return migration code" do
            expect(subject).to eql([
                <<-MIGRATION,
class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end

  def down
    drop_table :users
  end
end
MIGRATION
                <<-MIGRATION,
class CreateItems < ActiveRecord::Migration
  def up
    create_table :items do |t|
      t.string :name
      t.timestamps
    end
  end

  def down
    drop_table :items
  end
end
MIGRATION
            ])
          end
        end

        context "if type is :kve" do
          let(:type) do
            :kvs
          end

          it { is_expected.to eq "" }
        end
      end
    end
  end
end
