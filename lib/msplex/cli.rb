module Msplex
  class Cli < Thor
    desc "new", "Create a new application"
    def new
      raise NotImplementedError
    end

    desc "service", "Create a new service"
    def service
      raise NotImplementedError
    end

    desc "generate", "Generate application codes"
    option :schema_dir, type: :string, desc: "Schema directory", aliases: :d
    option :out_dir, type: :string, desc: "Directory for output artifacts", aliases: :o
    def generate
      application, frontend, services, databases = Msplex.read_schema_directory(options[:schema_dir])
      generator = Msplex::Generator.new(application, frontend, services, databases, options[:out_dir])

      generator.generate_compose
      generator.generate_frontend
      generator.generate_services
    end
  end
end
