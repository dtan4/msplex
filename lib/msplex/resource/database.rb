module Msplex
  module Resource
    class InvalidDatabaseTypeError < StandardError; end

    class Database
      extend Forwardable

      DB_TYPES = {
        kvs: "KVS",
        rdb: "RDB",
      }

      delegate %i(name tables compose config definitions gem image migrations all create read) => :@delegator

      def self.read_schema(path)
        schema = Utils.symbolize_keys(YAML.load_file(path))
        self.new(schema[:type], schema[:name], schema[:tables])
      end

      def initialize(type, name, tables)
        raise InvalidDatabaseTypeError, "#{type} is invalid database type" unless DB_TYPES.keys.include?(type.to_sym)
        @delegator = eval(DB_TYPES[type.to_sym]).new(name, tables)
      end
    end
  end
end
