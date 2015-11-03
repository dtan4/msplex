module Msplex
  module Resource
    class InvalidDatabaseTypeError < StandardError; end

    class Database
      DB_TYPES = %i(rds kvs)

      attr_reader :name, :type, :tables

      def initialize(name, type, tables)
        raise InvalidDatabaseTypeError, "#{type} is invalid database type" unless DB_TYPES.include?(type)

        @name = name
        @type = type
        @tables = tables
      end

      def compose
        {
          image: image,
        }
      end

      def config
        return "" unless rds?

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
  database: #{db_name("production")}
CONFIG
      end

      def gem
        rds? ? { gem: "pg", version: "0.18.3" } : { gem: "redis", version: "3.2.1" }
      end

      def image
        rds? ? "postgres:9.4" : "redis:3.0"
      end

      def migration
        rds? ? tables.map { |table, fields| table_migration(table, fields) } : ""
      end

      def rds?
        @type == :rds
      end

      private

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

      def table_migration(table, fields)
        <<-MIGRATION
class #{migration_class_of(table)} < ActiveRecord::Migration
  def up
#{Utils.indent(up_migration(table, fields), 4)}
  end

  def down
#{Utils.indent(down_migration(table), 4)}
  end
end
MIGRATION
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
