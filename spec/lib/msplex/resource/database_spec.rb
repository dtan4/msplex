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

        context "if type is unknown" do
          let(:type) do
            :unknown
          end

          it "should generate docker-compose.yml" do
            expect(subject).to eql({
              image: nil,
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

        context "if type is unknown" do
          let(:type) do
            :unknown
          end

          it { is_expected.to eq nil }
        end
      end
    end
  end
end
