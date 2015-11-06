require "spec_helper"

module Msplex
  module Resource
    describe RDB do
      let(:name) do
        "sampledb"
      end

      let(:tables) do
        {
          users: [
            { key: "name", type: :string },
            { key: "description", type: :string },
          ],
          items: [
            { key: "name", type: :string },
          ]
        }
      end

      let(:rdb) do
        described_class.new(name, tables)
      end

      describe "#initialize" do
        it "should return new RDB instance" do
          expect(rdb).to be_a described_class
        end
      end

      describe "#compose" do
        subject { rdb.compose }

        it "should generate docker-compose.yml" do
          expect(subject).to eql({
            image: "postgres:9.4",
          })
        end
      end

      describe "#config" do
        subject { rdb.config }

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

      describe "#definitions"do
        subject { rdb.definitions }

        it "should generate class defitions of ActiveRecord" do
          expect(subject).to eql([
                <<-DEFINITIONS,
class User < ActiveRecord::Base
end
DEFINITIONS
                <<-DEFINITIONS,
class Item < ActiveRecord::Base
end
DEFINITIONS
          ])
        end
      end

      describe "#gem" do
        subject { rdb.gem }

        it "should return adapter gem and its version" do
          expect(subject).to eql({
            gem: "pg",
            version: "0.18.3",
          })
        end
      end

      describe "#image" do
        subject { rdb.image }

        it { is_expected.to eq "postgres:9.4" }
      end

      describe "#migrations" do
        subject { rdb.migrations }

        it "should return migration code" do
          expect(subject).to eql([
            {
              name: "create_users",
              migration: <<-MIGRATION,
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
            },
            {
              name: "create_items",
              migration: <<-MIGRATION,
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
            }
          ])
        end
      end

      describe "#params" do
        let(:table) do
          :users
        end

        subject { rdb.params(table) }

        it "should generate assignment statements" do
          expect(subject).to eq <<-PARAMS
user_name = params[:users][:name]
user_description = params[:users][:description]
PARAMS
        end
      end

      describe "#list" do
        let(:table) do
          :users
        end

        subject { rdb.list(table) }

        it { is_expected.to eq 'User.all' }
      end

      describe "#create" do
        let(:table) do
          :users
        end

        let(:conditions) do
          { id: 1, name: "hoge" }
        end

        subject { rdb.create(table, conditions) }

        it { is_expected.to eq 'User.new(id: 1, name: "hoge")' }
      end

      describe "#read" do
        let(:table) do
          :users
        end

        let(:conditions) do
          { id: 1, name: "hoge" }
        end

        subject { rdb.read(table, conditions) }

        it { is_expected.to eq 'User.where(id: 1, name: "hoge")' }
      end
    end
  end
end
