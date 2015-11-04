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
