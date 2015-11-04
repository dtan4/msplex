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

    def generate_services
      service_database_pairs.each do |service, database|
        service_dir = File.join(@out_dir, "services", service.name)
        FileUtils.mkdir_p(service_dir)
        generate_dockerfile(service, service_dir)
        generate_gemfile(service, service_dir)
      end
    end

    private

    def generate_dockerfile(resource, base_dir)
      File.open(File.join(base_dir, "Dockerfile"), "w+") { |f| f.puts resource.dockerfile }
    end

    def generate_gemfile(resource, base_dir)
      File.open(File.join(base_dir, "Gemfile"), "w+") { |f| f.puts resource.gemfile }
    end

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
