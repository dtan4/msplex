require "spec_helper"

module Msplex
  module Resource
    describe RDB do
      let(:name) do
        "sample"
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

      describe "#compose_service_name" do
        subject { rdb.compose_service_name }

        it { is_expected.to eq "sample_db" }
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
  database: sample_development

test:
  <<: *default
  database: sample_test

production:
  <<: *default
  database: sample_production
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
user_id = params[:users][:id]
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

        it "should generate code for listing user" do
          expect(subject).to eq <<-LIST
users = User.all
result[:users] = users
LIST
        end
      end

      describe "#create" do
        let(:table) do
          :users
        end

        let(:params) do
          [:name]
        end

        subject { rdb.create(table, params) }

        it "should generate code for creating new user" do
          expect(subject).to eq <<-CREATE
user = User.new(name: user_name)
user.save!
result[:users] ||= []
result[:users] << user
CREATE
        end
      end

      describe "#read" do
        let(:table) do
          :users
        end

        let(:params) do
          [:id, :name]
        end

        subject { rdb.read(table, params) }

        it "should generate code for reading user" do
          expect(subject).to eq <<-READ
user = User.where(id: user_id, name: user_name)
result[:users] ||= []
result[:users] << user
READ
        end
      end
    end
  end
end
