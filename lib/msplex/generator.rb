module Msplex
  class Generator
    attr_reader :application, :frontend, :services, :databases, :out_dir

    def initialize(application, frontend, services, databases, out_dir)
      @application = application
      @frontend = frontend
      @services = services
      @databases = databases
      @out_dir = out_dir
    end

    def generate_compose
      compose_yml = { frontend: @frontend.compose(@services) }
      service_database_pairs.each { |service, database| compose_yml[service.name] = service.compose(database) }
      @databases.each { |database| compose_yml[database.name] = database.compose }
      write_compose(compose_yml)
    end

    private

    def service_database_pairs
      @service_database_pairs ||= @application.links.map do |link|
        service, database = *link.split(":")
        [@services.find { |s| s.name == service }, @databases.find { |d| d.name == database }]
      end
    end

    def write_compose(compose_yml)
      open(File.join(File.expand_path(out_dir), "docker-compose.yml"), "w+") do |f|
        f.puts Utils.desymbolize_keys(compose_yml).to_yaml.lines[1..-1]
      end
    end
  end
end
