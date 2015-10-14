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
    end
  end
end
