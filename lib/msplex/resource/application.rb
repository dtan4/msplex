module Msplex
  module Resource
    class Application
      attr_reader :name, :maintainer, :links

      def initialize(application_name, maintainer, links)
        @application_name = application_name
        @maintainer = maintainer
        @links = links
      end
    end
  end
end
