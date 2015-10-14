module Msplex
  class Generator
    attr_reader :frontend, :services, :databases

    def initialize(frontend, services, databases)
      @frontend = frontend
      @services = services
      @databases = databases
    end
  end
end
