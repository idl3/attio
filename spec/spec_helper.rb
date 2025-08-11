# frozen_string_literal: true

require "simplecov"
require "simplecov-console"

# Configure coverage formatters based on environment
SimpleCov.formatter = if ENV["COVERAGE"]
                        SimpleCov::Formatter::MultiFormatter.new([
                          SimpleCov::Formatter::HTMLFormatter,
                          SimpleCov::Formatter::Console,
                          SimpleCov::Formatter::SimpleFormatter,
                        ])
                      else
                        SimpleCov::Formatter::MultiFormatter.new([
                          SimpleCov::Formatter::HTMLFormatter,
                          SimpleCov::Formatter::Console,
                        ])
                      end

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/bin/"
  add_filter "/docs/"
  add_filter "/coverage/"
  add_filter "/test*"
  add_filter "/run_tests.rb"
  minimum_coverage 80 # Temporarily lowered during feature development
end

require "bundler/setup"
require "attio"
require "webmock/rspec"
require "pry"

# Load support files
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
