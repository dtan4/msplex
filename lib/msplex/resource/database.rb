module Msplex
  module Resource
    class InvalidDatabaseTypeError < StandardError; end

    class Database
      DB_TYPES = %i(rds kvs)

      attr_reader :name, :type, :fields

      def initialize(name, type, fields)
        raise InvalidDatabaseTypeError, "#{type} is invalid database type" unless DB_TYPES.include?(type)

        @name = name
        @type = type
        @fields = fields
      end

      def compose
        {
          image: image,
        }
      end

      def gem
        rds? ? { gem: "pg", version: "0.18.3" } : { gem: "redis", version: "3.2.1" }
      end

      def image
        rds? ? "postgres:9.4" : "redis:3.0"
      end

      def rds?
        @type == :rds
      end
    end
  end
end
