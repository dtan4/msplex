module Msplex
  module Resource
    class RDS < Database
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
  database: #{db_name("production")}
CONFIG
      end

      def find(table, conditions)
        "#{activerecord_class(table)}.find_by(#{find_conditions(conditions)})"
      end

      def gem
        { gem: "pg", version: "0.18.3" }
      end

      def image
        "postgres:9.4"
      end

      def migration
        tables.map { |table, fields| table_migration(table, fields) }
      end

      private

      def activerecord_class(table)
        table.to_s.singularize.capitalize
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

      def find_conditions(conditions)
        conditions.map { |key, value| "#{key}: #{value.inspect}" }.join(", ")
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
