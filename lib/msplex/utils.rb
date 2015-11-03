module Msplex
  module Utils
    def indent(lines, padding)
      lines.split("\n").map { |line| "#{' ' * padding}#{line}" }.join("\n")
    end
    module_function :indent
  end
end
