module Msplex
  class Generator
    attr_reader :application, :frontend, :services, :databases

    def initialize(application, frontend, services, databases)
      @application = application
      @frontend = frontend
      @services = services
      @databases = databases
    end
  end
end
