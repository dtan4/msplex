module Msplex
  module Resource
    class Service
      attr_reader :name, :actions

      def initialize(name, actions)
        @name = name
        @actions = actions
      end

      def compose
        {
          image: image,
        }
      end

      def image
        "ruby:2.2.3"
      end
    end
  end
end
