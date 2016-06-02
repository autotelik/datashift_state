module DatashiftJourney

  class Engine < ::Rails::Engine

    isolate_namespace DatashiftJourney

    # Add a load path for this specific Engine
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    config.to_prepare do
      Dir.glob(File.join(Engine.root, 'app/decorators', '**/*_decorator*.rb')).each do |c|
        require_dependency(c)
      end
    end

    # Our migration should be added by generators that copy specific migrations over

   # initializer :append_migrations, before: :load_config_initializers do |app|
      #unless app.root.to_s.match root.to_s
        #config.paths['db/migrate'].expanded.each do |expanded_path|
          # puts "Copy Migrations from DSC [#{expanded_path.inspect}]"
          # puts "To #{app.config.paths["db/migrate"].expanded.inspect}"
          #Rails.application.config.paths['db/migrate'] << expanded_path
        #end
      #end
    #end

    # we use rspec for testing
    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end


    # Make Shared examples and Support files available to Apps and other Engines
    # TODO: - make this optional - i.e configurable so Apps/Engines can easily pull this in themselves if they wish
    if Rails.env.test? && defined?(RSpec)
      initializer 'datashift_journey.shared_examples' do
        RSpec.configure do
          Dir[File.join(File.expand_path('../../../spec/shared_examples', __FILE__), '**/*.rb')].each { |f| require f }
          Dir[File.join(File.expand_path('../../../spec/support', __FILE__), '**/*.rb')].each { |f| require f }
        end
      end

      config.autoload_paths << File.expand_path('../../../spec/support', __FILE__)
    end

  end

end

begin
  require_relative 'exceptions'
  require_relative 'configuration'
  require_relative 'datashift_journey'
  require_relative 'state_machines/state_machine_core_ext'
rescue => x
  # TODO: - remove this block once gem stable
  puts x.inspect
end