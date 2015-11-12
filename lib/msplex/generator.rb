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

    def generate_frontend
      frontend_dir = File.join(@out_dir, "frontend")
      FileUtils.mkdir_p(frontend_dir)

      generate_app_rb(@frontend, frontend_dir)
      generate_config_ru(@frontend, frontend_dir)
      generate_dockerfile(@frontend, frontend_dir)
      generate_frontend_gemfile(frontend_dir)
      generate_views(@frontend, frontend_dir)
    end

    def generate_services
      service_database_pairs.each do |service, database|
        service_dir = File.join(@out_dir, "services", service.name)
        FileUtils.mkdir_p(service_dir)

        generate_app_rb(service, service_dir)
        generate_config_ru(service, service_dir)
        generate_database_yml(database, service_dir)
        generate_dockerfile(service, service_dir)
        generate_service_gemfile(service, database, service_dir)
        generate_migration_files(database, service_dir)
      end
    end

    private

    def generate_app_rb(resource, base_dir)
      File.open(File.join(base_dir, "app.rb"), "w+") { |f| f.puts resource.app_rb }
    end

    def generate_config_ru(resource, base_dir)
      File.open(File.join(base_dir, "config.ru"), "w+") { |f| f.puts resource.config_ru }
    end

    def generate_database_yml(database, base_dir)
      FileUtils.mkdir(File.join(base_dir, "config"))
      File.open(File.join(base_dir, "config", "database.yml"), "w+") { |f| f.puts database.config }
    end

    def generate_dockerfile(resource, base_dir)
      File.open(File.join(base_dir, "Dockerfile"), "w+") { |f| f.puts resource.dockerfile }
    end

    def generate_frontend_gemfile(base_dir)
      File.open(File.join(base_dir, "Gemfile"), "w+") { |f| f.puts @frontend.gemfile }
    end

    def generate_service_gemfile(service, database, base_dir)
      File.open(File.join(base_dir, "Gemfile"), "w+") { |f| f.puts service.gemfile(database) }
    end

    def generate_layout_slim(frontend, base_dir)
      File.open(File.join(base_dir, "views", "layout.slim"), "w+") { |f| f.puts frontend.layout_html(@application) }
    end

    def generate_migration_file(migration, index, base_dir)
      filename = "#{sprintf('%03d', index + 1)}_#{migration[:name]}.rb"
      open(File.join(base_dir, "db", filename), "w+") { |f| f.puts migration[:migration] }
    end

    def generate_migration_files(database, base_dir)
      FileUtils.mkdir(File.join(base_dir, "db"))
      database.migrations.each.with_index { |migration, index| generate_migration_file(migration, index, base_dir) }
    end

    def generate_page_slims(frontend, base_dir)
      frontend.page_htmls.each { |page| File.open(File.join(base_dir, "views", "#{page[:name]}.slim"), "w+") { |f| f.puts page[:html] } }
    end

    def generate_views(frontend, base_dir)
      FileUtils.mkdir(File.join(base_dir, "views"))
      generate_layout_slim(frontend, base_dir)
      generate_page_slims(frontend, base_dir)
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
