module Msplex
  module Resource
    class KVS < Database
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
        ""
      end

      def definitions
        tables.map { |table, fields| ohm_definition(table, fields) }
      end

      def gem
        { gem: "ohm", version: "2.3.0" }
      end

      def image
        "redis:3.0"
      end

      def migrations
        ""
      end

      def params(table)
        tables[table.to_sym].map do |field|
          "#{table.to_s.singularize}_#{field[:key]} = params[:#{table}][:#{field[:key]}]"
        end.join("\n") << "\n"
      end

      def all

      end

      def create

      end

      def read

      end

      private

      def ohm_attributes(fields)
        fields.map { |field| "attribute :#{field[:key]}" }.join("\n")
      end

      def ohm_class(table)
        table.to_s.singularize.capitalize
      end

      def ohm_definition(table, fields)
        <<-DEFINITION
class #{ohm_class(table)} < Ohm::Model
#{Utils.indent(ohm_attributes(fields), 2)}
end
DEFINITION
      end
    end
  end
end
