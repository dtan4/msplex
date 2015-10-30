module Msplex
  module Resource
    class Database
      DB_TYPES = %i(rds kvs)

      attr_reader :name, :type, :fields

      def initialize(name, type, fields)
        @name = name
        @type = type
        @fields = fields
      end

      def compose
        {
          image: docker_image,
        }
      end

      def docker_image
        case @type
        when :rds
          "postgres:9.4"
        when :kvs
          "redis:3.0"
        else
          nil
        end
      end
    end
  end
end
