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
        ""
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
    end
  end
end
