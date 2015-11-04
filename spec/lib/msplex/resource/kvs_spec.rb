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

        it { is_expected.to eq "" }
      end

      describe "#gem" do
        subject { kvs.gem }

        it "should return adapter gem adn its version" do
          expect(subject).to eql({
            gem: "redis",
            version: "3.2.1",
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

      describe "#create" do
        pending
      end

      describe "#read" do
        pending
      end
    end
  end
end
