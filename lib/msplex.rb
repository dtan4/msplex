require "active_support/inflector"
require "erb"
require "fileutils"
require "forwardable"
require "thor"
require "yaml"

require "msplex/cli"
require "msplex/generator"
require "msplex/resource/application"
require "msplex/resource/database"
require "msplex/resource/frontend"
require "msplex/resource/kvs"
require "msplex/resource/rdb"
require "msplex/resource/service"
require "msplex/utils"
require "msplex/version"

module Msplex
  def read_schema_directory(schema_dir)
    full_schema_dir = File.expand_path(schema_dir)
    application = Msplex::Resource::Application.read_schema(File.join(full_schema_dir, "application.yml"))
    frontend = Msplex::Resource::Frontend.read_schema(File.join(full_schema_dir, "frontend.yml"))
    services = read_service_schemas(full_schema_dir)
    databases = read_database_schemas(full_schema_dir)

    return application, frontend, services, databases
  end
  module_function :read_schema_directory

  def read_database_schemas(schema_dir)
    Dir.glob(File.join(schema_dir, "databases", "*.yml")).inject([]) do |result, schema|
      result << Msplex::Resource::Database.read_schema(schema)
      result
    end
  end
  module_function :read_database_schemas

  def read_service_schemas(schema_dir)
    Dir.glob(File.join(schema_dir, "services", "*.yml")).inject([]) do |result, schema|
      result << Msplex::Resource::Service.read_schema(schema)
      result
    end
  end
  module_function :read_service_schemas
end
