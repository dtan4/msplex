module Msplex
  module Resource
    class InvalidDatabaseTypeError < StandardError; end

    class Database
      extend Forwardable

      DB_TYPES = {
        kvs: "KVS",
        rds: "RDS",
      }

      delegate %i(compose config gem image migration) => :@delegator

      def initialize(type, name, tables)
        raise InvalidDatabaseTypeError, "#{type} is invalid database type" unless DB_TYPES.keys.include?(type)
        @delegator = eval(DB_TYPES[type]).new(name, tables)
      end
    end
  end
end
