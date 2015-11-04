module Msplex
  module Resource
    class Application
      attr_reader :name, :maintainer, :links

      def self.read_schema(path)
        schema = Utils.symbolize_keys(YAML.load_file(path))
        self.new(schema[:name], schema[:maintainer], schema[:links])
      end

      def initialize(name, maintainer, links)
        @name = name
        @maintainer = maintainer
        @links = links
      end
    end
  end
end
