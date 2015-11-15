require "spec_helper"

module Msplex
  module Resource
    describe KVS do
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

      let(:kvs) do
        described_class.new(name, tables)
      end

      describe "#initialize" do
        it "should return new KVS instance" do
          expect(kvs).to be_a described_class
        end
      end

      describe "#compose" do
        subject { kvs.compose }
        it "should generate docker-compose.yml" do
          expect(subject).to eql({
            image: "redis:3.0",
          })
        end
      end

      describe "#config" do
        subject { kvs.config }

        it { is_expected.to eq "" }
      end

      describe "#definitions" do
        subject { kvs.definitions }

        it "should generate class defitions of ActiveRecord" do
          expect(subject).to eql([
                <<-DEFINITIONS,
class User < Ohm::Model
  attribute :name
  attribute :description

  index :name
  index :description
end
DEFINITIONS
                <<-DEFINITIONS,
class Item < Ohm::Model
  attribute :name

  index :name
end
DEFINITIONS
          ])
        end
      end

      describe "#gem" do
        subject { kvs.gem }

        it "should return adapter gem adn its version" do
          expect(subject).to eql({
            gem: "ohm",
            version: "2.3.0",
          })
        end
      end

      describe "#image" do
        subject { kvs.image }

        it { is_expected.to eq "redis:3.0" }
      end

      describe "#migrations" do
        subject { kvs.migrations }

        it { is_expected.to eq "" }
      end

      describe "#params" do
        let(:table) do
          :users
        end

        subject { kvs.params(table) }

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

        subject { kvs.list(table) }

        it "should generate code for listing user" do
          expect(subject).to eq <<-LIST
users = User.all.to_a
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

        subject { kvs.create(table, params) }

        it "should generate code for creating new user" do
          expect(subject).to eq <<-CREATE
user = User.create(name: user_name)
result[:users] ||= []
result[:users] << user
CREATE
        end
      end

      describe "#read" do
        pending
      end
    end
  end
end
