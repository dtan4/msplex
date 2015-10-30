require "spec_helper"

module Msplex
  module Resource
    describe Service do
      let(:name) do
        "sampleservice"
      end

      let(:actions) do
        []
      end

      let(:service) do
        described_class.new(name, actions)
      end

      describe "#image" do
        subject { service.image }

        it { is_expected.to eq "ruby:2.2.3" }
      end
    end
  end
end
