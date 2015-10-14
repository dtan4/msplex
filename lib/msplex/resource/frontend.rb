module Msplex
  module Resource
    class Frontend
      attr_reader :elements

      def initialize(elements)
        @elements = elements
      end
    end
  end
end
