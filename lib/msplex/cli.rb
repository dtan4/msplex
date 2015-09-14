module Msplex
  class Cli < Thor
    desc "new", "Create a new application"
    def new
      puts "new"
    end

    desc "service", "Create a new service"
    def service
      puts "service"
    end

    desc "generate", "Generate application codes"
    def generate
      puts "genrate"
    end
  end
end
