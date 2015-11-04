require 'codeclimate-test-reporter'

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter,
  ]
end

require 'rspec/its'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'msplex'

def fixture_path(fixture_name)
  File.expand_path(File.join("..", "fixtures", fixture_name), __FILE__)
end
