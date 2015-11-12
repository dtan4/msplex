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

      def list(table)
        <<-LIST
#{table.to_s} = #{ohm_class(table)}.all.to_a
result[:users] = users
LIST
      end

      def create(table, params)
        <<-CREATE
#{table.to_s.singularize} = #{ohm_class(table)}.create(#{prettify_params(table, params)})
result[:users] ||= []
result[:users] << user
CREATE
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

      def param_name_of(table, param)
        "#{table.to_s.singularize}_#{param}"
      end

      def prettify_params(table, params)
        params.map { |param| "#{param}: #{param_name_of(table, param)}" }.join(", ")
      end
    end
  end
end
