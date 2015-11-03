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

      def gem
        { gem: "redis", version: "3.2.1" }
      end

      def image
        "redis:3.0"
      end

      def migration
        ""
      end
    end
  end
end
