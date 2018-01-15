require 'bundler/setup'
require 'rack/test'
require 'rspec'
require 'simplecov'

ENV['RACK_ENV'] = 'test'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.bundle/'
  add_filter '/vendor/'
end

require 'environmate/app'

Environmate.load_configuration('test', 'spec/fixtures/test_config.yml')

module RSpecMixin
  include Rack::Test::Methods
  def app
    Environmate::App
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
