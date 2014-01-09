require 'devise/rails/routes'
require 'devise/rails/warden_compat'

module Devise
  class Engine < ::Rails::Engine
    config.devise = Devise

    # Initialize Warden and copy its configurations.
    config.app_middleware.use Warden::Manager do |config|
      Devise.warden_config = config
    end

    # Force routes to be loaded if we are doing any eager load.
    config.before_eager_load { |app| app.reload_routes! }

    # Removing the controllers constants. Since controllers are lazily-loaded need to get them first.
    config.after_initialize do
      unless Devise.generate_controllers
        %w(confirmation omniauth_callback password registration session unlock).each do |mod|
          controller_name = mod.classify.pluralize + 'Controller'
          Devise.const_get(controller_name.to_sym)
          Devise.send(:remove_const, controller_name.to_sym)
        end
        Object.const_get(:DeviseController)
        Object.send(:remove_const, :DeviseController)
      end
    end

    initializer "devise.url_helpers" do
      Devise.include_helpers(Devise::Controllers)
    end

    initializer "devise.omniauth" do |app|
      Devise.omniauth_configs.each do |provider, config|
        app.middleware.use config.strategy_class, *config.args do |strategy|
          config.strategy = strategy
        end
      end

      if Devise.omniauth_configs.any?
        Devise.include_helpers(Devise::OmniAuth)
      end
    end

    initializer "devise.secret_key" do
      Devise.token_generator ||=
        if secret_key = Devise.secret_key
          Devise::TokenGenerator.new(
            Devise::CachingKeyGenerator.new(Devise::KeyGenerator.new(secret_key))
          )
        end
    end

    initializer "devise.fix_routes_proxy_missing_respond_to_bug" do
      # Deprecate: Remove once we move to Rails 4 only.
      ActionDispatch::Routing::RoutesProxy.class_eval do
        def respond_to?(method, include_private = false)
          super || routes.url_helpers.respond_to?(method)
        end
      end
    end
  end
end
