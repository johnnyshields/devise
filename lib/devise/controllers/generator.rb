module Devise
  module Controllers
    class Generator

      AVAILABLE_CONTROLLERS = [:confirmation, :omniauth_callback, :password, :registration, :session, :unlock]

      attr_reader :scope, :controllers

      def initialize(scope = :devise, parent = "ApplicationController", *controllers)
        @scope       = scope.to_sym
        @parent      = parent.constantize
        @controllers = only_available(controllers)
      end

      # First generate the `Devise::BaseController < ApplicationController`
      # then generate the `Devise::SessionsController < Devise::BaseController`
      def generate
        base_controller
        controllers.each do |controller|
          module_controller(controller)
        end
      end

      class << self
        def generate(scope = :devise, parent = "ApplicationController", *controllers)
          new(scope, parent, *controllers).generate
        end
      end

      private

        def only_available(args)
          return AVAILABLE_CONTROLLERS if args.blank? or args == [:all]
          AVAILABLE_CONTROLLERS & Array(args)
        end

        def base_controller_name
          if scope == :devise
            "Devise::BaseController"
          else
            "#{scope.to_s.classify}::Devise::BaseController"
          end
        end

        def controller_name(option)
          "#{option.to_s.classify.pluralize}Controller"
        end

        def scoped_module
          scope.to_s.classify.constantize
        rescue StandardError
          Object.const_set(scope.to_s.classify, Module.new)
        end

        def base_controller
          klass = Class.new @parent do
            include Devise::Mixins::Base
          end
          scoped_module.const_set(:BaseController, klass)
        end

        def module_controller(controller)
          name = controller_name(controller).to_sym 
          klass = Class.new(base_controller_name.constantize) do
            include Devise::Mixins.const_get(controller.to_s.classify)
          end
          scoped_module.const_set(name, klass)
        end

    end
  end
end
