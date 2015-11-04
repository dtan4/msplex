require "spec_helper"

module Msplex
  module Resource
    describe Application do
      let(:name) do
        "sample"
      end

      let(:maintainer) do
        "Tanaka Taro"
      end

      let(:links) do
        []
      end

      let(:application) do
        described_class.new(name, maintainer, links)
      end

      describe ".read_schema" do
        subject { described_class.read_schema(path) }

        context "when the given schema is valid" do
          let(:path) do
            fixture_path("valid_application.yml")
          end

          it { is_expected.to be_a described_class }
          its(:name) { is_expected.to eq "sample" }
          its(:maintainer) { is_expected.to eq "Tanaka Taro" }
          its(:links) { is_expected.to eql ["hogeservice:hogedb", "fugaservice:fugadb"] }
        end

        context "when the given schema is invalid" do
          pending
        end
      end
    end
  end
end
