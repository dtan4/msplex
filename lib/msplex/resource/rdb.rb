module Msplex
  module Resource
    class RDB < Database
      attr_reader :name, :tables

      def initialize(name, tables)
        @name = name
        @tables = tables
      end

      def compose
        {
          image: image,
        }
      end

      def compose_service_name
        @compose_service_name ||= "#{@name}_db"
      end

      def config
        <<-CONFIG
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  user: postgres
  host: db
  port: 5432

development:
  <<: *default
  database: #{db_name("development")}

test:
  <<: *default
  database: #{db_name("test")}

production:
  <<: *default
  database: #{db_name("production")}
CONFIG
      end

      def definitions
        tables.map { |table, fields| activerecord_definition(table, fields) }
      end

      def gem
        { gem: "pg", version: "0.18.3" }
      end

      def image
        "postgres:9.4"
      end

      def migrations
        tables.map { |table, fields| table_migration(table, fields) }
      end

      def params(table)
        [
          "json_params = JSON.parse(request.body.read, symbolize_names: true)",
          param_assignment_statement(table, "id")
        ].concat(
          tables[table.to_sym].map { |field| param_assignment_statement(table, field[:key]) }
        ).join("\n") << "\n"
      end

      def list(table)
        <<-LIST
#{table.to_s} = #{activerecord_class(table)}.all
result[:#{table.to_s}] = #{table.to_s}
LIST
      end

      def create(table, params)
        <<-CREATE
#{table.to_s.singularize} = #{activerecord_class(table)}.new(#{prettify_params(table, params)})
#{table.to_s.singularize}.save!
result[:#{table.to_s}] ||= []
result[:#{table.to_s}] << #{table.to_s.singularize}
CREATE
      end


      def read(table, params)
        <<-READ
#{table.to_s.singularize} = #{activerecord_class(table)}.where(#{prettify_params(table, params)})
result[:#{table.to_s}] ||= []
result[:#{table.to_s}] << #{table.to_s.singularize}
READ
      end

      private

      def activerecord_class(table)
        table.to_s.singularize.capitalize
      end

      def activerecord_definition(table, fields)
        <<-DEFINITION
class #{activerecord_class(table)} < ActiveRecord::Base
end
DEFINITION
      end

      def db_name(environment)
        "#{@name}_#{environment}"
      end

      def down_migration(table)
        "drop_table :#{table}"
      end

      def field_migrations(fields)
        fields
          .reject { |field| field[:key] == "id" }
          .map { |field| "  t.#{field[:type]} :#{field[:key]}" }
          .concat(["  t.timestamps"])
          .join("\n")
      end

      def migration_class_of(table)
        "Create#{table.capitalize}"
      end

      def migration_name_of(table)
        "create_#{table}"
      end

      def param_assignment_statement(table, param)
        "#{param_name_of(table, param)} = json_params[:#{table}][:#{param}]"
      end

      def param_name_of(table, param)
        "#{table.to_s.singularize}_#{param}"
      end

      def prettify_params(table, params)
        params.map { |param| "#{param}: #{param_name_of(table, param)}" }.join(", ")
      end

      def table_migration(table, fields)
        {
          name: migration_name_of(table),
          migration: <<-MIGRATION
class #{migration_class_of(table)} < ActiveRecord::Migration
  def up
#{Utils.indent(up_migration(table, fields), 4)}
  end

  def down
#{Utils.indent(down_migration(table), 4)}
  end
end
MIGRATION
        }
      end

      def up_migration(table, fields)
        <<-MIGRATION
create_table :#{table} do |t|
#{field_migrations(fields)}
end
MIGRATION
      end
    end
  end
end
