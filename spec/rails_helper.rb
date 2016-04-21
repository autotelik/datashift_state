
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'

# For stubbing external services
# https://github.com/vcr/vcr
require 'vcr'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
unless $LOAD_PATH.include?('spec/support/base')
  $LOAD_PATH.unshift('spec/support/base')
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

# "spatial_ref_sys" is a Postgis (postgres) table that should not be truncated (defines SRIDs etc)
DB_CLEANER_TRUNCATION_OPTS = { except: %w(spatial_ref_sys) }.freeze

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods

  ActiveRecord::Migration.maintain_test_schema!

  # Use seed data in some places rather than Factories so don't clean
  # certain 'static' tables
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation, DB_CLEANER_TRUNCATION_OPTS
    DatabaseCleaner.clean
  end

  config.before do |example|
    md = example.metadata
    DatabaseCleaner.strategy = :transaction

    Capybara.current_driver =
      if md[:driver].present?
        md[:driver]
      elsif md[:js] || md[:javascript]
        :poltergeist
      else
        :rack_test
      end

    unless Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :truncation, DB_CLEANER_TRUNCATION_OPTS
    end

    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  # Enables shortcut, t() instead of I18n.t() in tests
  config.include AbstractController::Translation
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock

  # to quickly ignore certain hosts can use following style
  # c.ignore_hosts 'addressfacade.cloudapp.net'
  c.ignore_hosts '127.0.0.1'
  # c.allow_http_connections_when_no_cassette = true
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
