module Msplex
  module Resource
    class Application
      attr_reader :name
      attr_reader :maintainer

      def initialize(application_name, maintainer)
        @application_name = application_name
        @maintainer = maintainer
      end
    end
  end
end
