module Msplex
  module Resource
    class Service
      attr_reader :name, :actions

      def initialize(name, actions)
        @name = name
        @actions = actions
      end
    end
  end
end
