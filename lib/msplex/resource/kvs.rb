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
        { gem: "redis", version: "3.2.1" }
      end

      def image
        "redis:3.0"
      end

      def migrations
        ""
      end

      def create

      end

      def read

      end
    end
  end
end
