require "spec_helper"

module Msplex
  describe "#read_schema_directory" do
    let(:schema_dir) do
      fixture_path("sample")
    end

    subject { Msplex.read_schema_directory(schema_dir) }

    it "should return resource instances" do
      application, frontend, services, databases = subject
      expect(application).to be_a Msplex::Resource::Application
      expect(frontend).to be_a Msplex::Resource::Frontend
      expect(services).to be_a Array
      expect(databases).to be_a Array
    end

    it "should return the Array of Service" do
      _, _, services, _ = subject
      expect(services.length).to eq 2
      expect(services[0].name).to eq "fuga"
      expect(services[1].name).to eq "hoge"
    end

    it "should return the Array of Database" do
      _, _, _, databases = subject
      expect(databases.length).to eq 2
      expect(databases[0].name).to eq "fuga"
      expect(databases[1].name).to eq "hoge"
    end
  end
end
