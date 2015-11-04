module Msplex
  module Utils
    def indent(lines, padding)
      lines.split("\n").map { |line| "#{' ' * padding}#{line}" }.join("\n")
    end
    module_function :indent

    def symbolize_keys(argument)
      if argument.class == Hash
        argument.inject({}) do |result, (key, value)|
          result[key.to_sym] = symbolize_keys(value)
          result
        end
      elsif argument.class == Array
        argument.map { |arg| symbolize_keys(arg) }
      else
        argument
      end
    end
    module_function :symbolize_keys

    def desymbolize_keys(argument)
      if argument.class == Hash
        argument.inject({}) do |result, (key, value)|
          result[key.to_s] = desymbolize_keys(value)
          result
        end
      elsif argument.class == Array
        argument.map { |arg| desymbolize_keys(arg) }
      else
        argument
      end
    end
    module_function :desymbolize_keys
  end
end
